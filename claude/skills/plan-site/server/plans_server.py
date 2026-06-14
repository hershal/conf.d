#!/usr/bin/env python3
"""Per-project Plan dashboard server.

Serves an ENTIRE project's plans/ directory from ONE process — replacing the old
"one pm2 server per plan-site" sprawl. It is the index: discovery is dynamic, so
new plans and plan-sites appear on a plain refresh, no rebuild step.

Routes
  /                    the dashboard — every plan-site and every .plan.md, with
                       live search / sort / filter (sites | plans | both)
  /_api/items.json     the discovered items as JSON (the dashboard's data source)
  /<YYYY-MM-DD-slug>/  a plan-site, served as static files (untouched)
  /<name>.plan.md      a markdown plan, rendered to a themed HTML page
  /<name>.plan-status.md  the as-built ledger, rendered the same way
  everything else      static files from plans/, with caching disabled

Stdlib only — no third-party dependencies, no network at view time.

Usage
  plans_server.py [PORT] [PLANS_DIR]
  plans_server.py --ensure-port [PLANS_DIR]   # reuse/pick a stable free port, print it
  plans_server.py --base-port   [PLANS_DIR]   # print the deterministic base port
"""
import http.server
import socketserver
import sys
import os
import re
import json
import html
import zlib
import socket
import time
from functools import partial

# ---------------------------------------------------------------------------
# Paths & ports
# ---------------------------------------------------------------------------

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))           # plans/_server
PORT_FILE = os.path.join(SCRIPT_DIR, ".port")
DATE_SLUG = re.compile(r"^(\d{4}-\d{2}-\d{2})-(.+)$")
MOCK_DIR_CANDIDATES = ("web/public/mocks", "frontend/public/mocks",
                       "public/mocks", "docs/mocks", "mocks")
STATE_WORDS = ("implemented", "cancelled", "chosen", "open")  # ui-mockups lifecycle


def default_plans_dir():
    """The dir we serve: the parent of _server (i.e. the project's plans/)."""
    return os.path.dirname(SCRIPT_DIR)


def base_port(plans_dir):
    """A stable per-project port in 8930-8989, derived from the abs path.

    crc32 (not hash()) so it is identical across runs — hash() is salted."""
    return 8930 + zlib.crc32(os.path.abspath(plans_dir).encode()) % 60


def port_is_free(port):
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        try:
            s.bind(("0.0.0.0", port))
            return True
        except OSError:
            return False


def ensure_port(plans_dir):
    """Reuse the recorded port if we have one; otherwise pick the first free
    port at/after the deterministic base and remember it. Reusing the recorded
    value (without probing) means our own running server doesn't look 'taken'."""
    if os.path.exists(PORT_FILE):
        try:
            with open(PORT_FILE) as f:
                return int(f.read().strip())
        except (ValueError, OSError):
            pass
    base = base_port(plans_dir)
    chosen = next((p for p in range(base, base + 200) if port_is_free(p)), base)
    try:
        with open(PORT_FILE, "w") as f:
            f.write(str(chosen))
    except OSError:
        pass
    return chosen


# ---------------------------------------------------------------------------
# Markdown -> HTML (compact, tuned for the `plan` skill's output)
# ---------------------------------------------------------------------------

def _inline(s):
    s = html.escape(s, quote=False)
    # code spans first so their contents aren't re-formatted
    s = re.sub(r"`([^`]+)`", lambda m: "<code>" + m.group(1) + "</code>", s)
    s = re.sub(r"\*\*([^*]+)\*\*", r"<strong>\1</strong>", s)
    s = re.sub(r"(?<![\w*])\*([^*\n]+)\*(?![\w*])", r"<em>\1</em>", s)
    s = re.sub(r"(?<![\w_])_([^_\n]+)_(?![\w_])", r"<em>\1</em>", s)
    s = re.sub(r"\[([^\]]+)\]\(([^)\s]+)\)", r'<a href="\2">\1</a>', s)
    return s


def _render_list(block):
    entries = []
    for ln in block:
        m = re.match(r"^(\s*)([-*+]|\d+\.)\s+(.*)$", ln)
        if m:
            indent = len(m.group(1).replace("\t", "  "))
            ordered = bool(re.match(r"\d+\.", m.group(2)))
            entries.append([indent, ordered, m.group(3)])
        elif entries and ln.strip():
            entries[-1][2] += " " + ln.strip()
    if not entries:
        return ""

    def build(i, indent):
        tag = "ol" if entries[i][1] else "ul"
        buf = []
        while i < len(entries) and entries[i][0] >= indent:
            cur_indent, _ordered, content = entries[i]
            if cur_indent > indent and buf:
                sub, i = build(i, cur_indent)
                buf[-1] += sub
                continue
            buf.append("<li>" + _inline(content))
            i += 1
        return "<" + tag + ">" + "".join(b + "</li>" for b in buf) + "</" + tag + ">", i

    return build(0, entries[0][0])[0]


def _render_table(rows):
    cells = [[c.strip() for c in re.sub(r"^\||\|$", "", r).split("|")] for r in rows]
    head, body = cells[0], cells[2:]
    out = ["<table><thead><tr>"]
    out += ["<th>" + _inline(c) + "</th>" for c in head]
    out.append("</tr></thead><tbody>")
    for row in body:
        out.append("<tr>" + "".join("<td>" + _inline(c) + "</td>" for c in row) + "</tr>")
    out.append("</tbody></table>")
    return "".join(out)


def md_to_html(text):
    _fm, body = split_frontmatter(text)
    lines = body.split("\n")
    out, para, i, n = [], [], 0, len(lines)

    def flush():
        if para:
            out.append("<p>" + _inline(" ".join(para)) + "</p>")
            para.clear()

    while i < n:
        line = lines[i]
        s = line.strip()
        if not s:
            flush(); i += 1; continue
        if s.startswith("```"):
            flush(); i += 1; code = []
            while i < n and not lines[i].strip().startswith("```"):
                code.append(lines[i]); i += 1
            i += 1
            out.append("<pre><code>" + html.escape("\n".join(code)) + "</code></pre>"); continue
        m = re.match(r"(#{1,6})\s+(.*)", s)
        if m:
            flush(); lvl = len(m.group(1))
            out.append("<h%d>%s</h%d>" % (lvl, _inline(m.group(2).strip()), lvl)); i += 1; continue
        if re.match(r"^(\*{3,}|-{3,}|_{3,})$", s):
            flush(); out.append("<hr>"); i += 1; continue
        if s.startswith(">"):
            flush(); quote = []
            while i < n and lines[i].strip().startswith(">"):
                quote.append(re.sub(r"^\s*>\s?", "", lines[i])); i += 1
            out.append("<blockquote>" + md_to_html("\n".join(quote)) + "</blockquote>"); continue
        if ("|" in s and i + 1 < n and "|" in lines[i + 1]
                and re.match(r"^\s*\|?[\s:|-]*-[\s:|-]*\|?\s*$", lines[i + 1])):
            flush(); rows = [line]
            i += 1
            while i < n and "|" in lines[i] and lines[i].strip():
                rows.append(lines[i]); i += 1
            out.append(_render_table(rows)); continue
        if re.match(r"^\s*([-*+]|\d+\.)\s+", line):
            flush(); block = []
            while i < n and (re.match(r"^\s*([-*+]|\d+\.)\s+", lines[i])
                             or (lines[i].startswith("  ") and lines[i].strip())):
                block.append(lines[i]); i += 1
            out.append(_render_list(block)); continue
        para.append(s); i += 1
    flush()
    return "\n".join(out)


# ---------------------------------------------------------------------------
# Discovery
# ---------------------------------------------------------------------------

def split_frontmatter(text):
    """Return (frontmatter_dict, body). Handles the simple `key: value` YAML the
    plan skill emits (nested list items under a key are ignored for metadata)."""
    if not text.startswith("---"):
        return {}, text
    parts = text.split("\n")
    if parts[0].strip() != "---":
        return {}, text
    fm, end = {}, None
    for idx in range(1, len(parts)):
        if parts[idx].strip() == "---":
            end = idx
            break
    if end is None:
        return {}, text
    for ln in parts[1:end]:
        m = re.match(r"^([A-Za-z_][\w-]*):\s*(.*)$", ln)
        if m and m.group(2).strip():
            fm[m.group(1).strip()] = m.group(2).strip()
    return fm, "\n".join(parts[end + 1:])


def extract_tldr(body):
    """Pull a one-line description from a plan's TL;DR blockquote, else the first
    real paragraph."""
    what = re.search(r"\*\*What:\*\*\s*(.+)", body)
    if what:
        return re.sub(r"[`*]", "", what.group(1)).strip().rstrip(".")
    for para in re.split(r"\n\s*\n", body):
        p = para.strip()
        if p and not p.startswith(("#", ">", "<!--", "---", "|")):
            return re.sub(r"\s+", " ", re.sub(r"[`*#]", "", p))[:240].strip()
    return ""


def scrape_site(index_path):
    """Best-effort title + description for a legacy plan-site lacking meta.json."""
    title = desc = ""
    try:
        with open(index_path, encoding="utf-8", errors="replace") as f:
            head = f.read(16000)
    except OSError:
        return title, desc
    m = re.search(r'<meta\s+name=["\']description["\']\s+content=["\']([^"\']+)', head, re.I)
    if m:
        desc = html.unescape(m.group(1)).strip()
    m = re.search(r"<title>(.*?)</title>", head, re.I | re.S)
    if m:
        title = html.unescape(re.sub(r"\s+", " ", m.group(1))).strip()
    if not title:
        m = re.search(r"<h1[^>]*>(.*?)</h1>", head, re.I | re.S)
        if m:
            title = html.unescape(re.sub(r"<[^>]+>", "", m.group(1))).strip()
    if not desc:
        m = re.search(r'class=["\'][^"\']*lede[^"\']*["\'][^>]*>(.*?)<', head, re.I | re.S)
        if m:
            desc = html.unescape(re.sub(r"<[^>]+>", "", m.group(1))).strip()
    return title, desc


def humanize(slug):
    return re.sub(r"[-_]+", " ", slug).strip().title()


# --- ui-mockups (mocks live OUTSIDE plans/, in the web app's public dir) ----

def find_mocks_dir(project_root):
    """Locate this project's ui-mockups directory. An explicit
    _server/config.json {"mocksDir": "..."} wins; otherwise probe common spots.
    Build artifacts (dist/.next) and agent worktrees are never candidates."""
    cfg = os.path.join(SCRIPT_DIR, "config.json")
    if os.path.exists(cfg):
        try:
            with open(cfg) as f:
                md = (json.load(f) or {}).get("mocksDir")
            if md:
                p = md if os.path.isabs(md) else os.path.join(project_root, md)
                if os.path.isdir(p):
                    return os.path.abspath(p)
        except (OSError, ValueError, AttributeError):
            pass
    for rel in MOCK_DIR_CANDIDATES:
        p = os.path.join(project_root, rel)
        if os.path.isdir(p):
            try:
                names = os.listdir(p)
            except OSError:
                continue
            if any(n.endswith("-mock.html") for n in names) or "index.html" in names:
                return os.path.abspath(p)
    return None


def mock_states(mocks_dir, mock_files):
    """Best-effort lifecycle badge per mock, scraped from the mocks index.html
    (the ui-mockups dashboard).

    Cards are packed tightly and lay out differently per project (the badge sits
    before the link in some indexes, after it in others), so a plain nearest-word
    scan grabs the neighbouring card's badge. Instead we match BADGE SPANS — a
    <span> whose text is exactly a lifecycle word — and bind each mock to the
    badge span nearest its link. This ignores 'Implemented:'/'Chosen:' prose in
    descriptions and the header legend. Falls back to nearest bare word for
    indexes that don't use span badges. Missing/unparseable → no badge."""
    states = {}
    try:
        with open(os.path.join(mocks_dir, "index.html"),
                  encoding="utf-8", errors="replace") as f:
            low = f.read().lower()
    except OSError:
        return states

    badges = [(m.start(), m.group(1)) for m in re.finditer(
        r"<span\b[^>]*>\s*(open|chosen|implemented|cancelled)\s*</span>", low)]

    # Drop a header legend (badge spans sitting before any mock card). Allow a
    # small margin so a layout that puts the badge just before the link is kept.
    if badges:
        hrefs = [h for h in (low.find(fn.lower()) for fn in mock_files) if h >= 0]
        if hrefs:
            badges = [b for b in badges if b[0] >= min(hrefs) - 150]

    for fn in mock_files:
        i = low.find(fn.lower())
        if i < 0:
            continue
        if badges:
            best, best_d = "", 700
            for pos, word in badges:
                if abs(pos - i) < best_d:
                    best_d, best = abs(pos - i), word
            if best:
                states[fn] = best
            continue
        # fallback: nearest bare state word within a card's span
        best, best_d = "", 401
        for w in STATE_WORDS:
            start = max(0, i - 400)
            while True:
                j = low.find(w, start, i + 400)
                if j < 0:
                    break
                if abs(j - i) < best_d:
                    best_d, best = abs(j - i), w
                start = j + 1
        if best:
            states[fn] = best
    return states


def scan_mock(path):
    """Title + one-line description for a single mock file."""
    try:
        with open(path, encoding="utf-8", errors="replace") as f:
            head = f.read(12000)
    except OSError:
        return "", ""

    def grab(p):
        m = re.search(p, head, re.I | re.S)
        return html.unescape(re.sub(r"\s+", " ", re.sub(r"<[^>]+>", "", m.group(1)))).strip() if m else ""

    title = re.sub(r"^Mock\s*[—\-:]\s*", "",
                   grab(r"<h1[^>]*>(.*?)</h1>") or grab(r"<title>(.*?)</title>")).strip()
    desc = grab(r"<h1[^>]*>.*?</h1>\s*<p[^>]*>(.*?)</p>")
    if desc.lower().startswith("back to"):
        desc = ""
    return title, desc


def scan(plans_dir, mocks_dir=None):
    """Walk plans/ once and return the list of items (sites + plans + mocks)."""
    items = []
    try:
        names = sorted(os.listdir(plans_dir))
    except OSError:
        return items

    statuses = {n[:-len(".plan-status.md")]
                for n in names if n.endswith(".plan-status.md")}

    for name in names:
        path = os.path.join(plans_dir, name)

        # --- plan-site: a dated dir with an index.html ----------------------
        if os.path.isdir(path) and not name.startswith((".", "_")):
            index = os.path.join(path, "index.html")
            if not os.path.exists(index):
                continue
            m = DATE_SLUG.match(name)
            date, slug = (m.group(1), m.group(2)) if m else (None, name)
            title = desc = ""
            meta_path = os.path.join(path, "meta.json")
            if os.path.exists(meta_path):
                try:
                    with open(meta_path) as f:
                        meta = json.load(f)
                    title = (meta.get("title") or "").strip()
                    desc = (meta.get("description") or "").strip()
                    date = meta.get("date") or date
                except (OSError, ValueError, AttributeError):
                    pass
            if not title or not desc:
                st, sd = scrape_site(index)
                title = title or st
                desc = desc or sd
            pages = sum(1 for f in os.listdir(path) if f.endswith(".html"))
            items.append({
                "type": "site",
                "id": name,
                "title": title or humanize(slug),
                "slug": slug,
                "date": date,
                "status": "",
                "description": desc,
                "href": "/" + name + "/",
                "statusHref": "",
                "pages": pages,
                "mtime": int(os.path.getmtime(index)),
            })
            continue

        # --- markdown plan ---------------------------------------------------
        if name.endswith(".plan.md"):
            stem = name[:-len(".plan.md")]
            try:
                with open(path, encoding="utf-8", errors="replace") as f:
                    text = f.read()
            except OSError:
                continue
            fm, bdy = split_frontmatter(text)
            m = DATE_SLUG.match(stem)
            date, slug = (m.group(1), m.group(2)) if m else (None, stem)
            status_name = stem + ".plan-status"
            items.append({
                "type": "plan",
                "id": name,
                "title": fm.get("name") or humanize(slug),
                "slug": slug,
                "date": fm.get("created") or date,
                "status": fm.get("status", ""),
                "description": extract_tldr(bdy),
                "author": fm.get("author", ""),
                "href": "/" + name,
                "statusHref": ("/" + status_name + ".md") if stem in statuses else "",
                "mtime": int(os.path.getmtime(path)),
            })

    # --- mocks (from the project's ui-mockups dir, served via /_mocks/) ------
    if mocks_dir:
        try:
            mfiles = sorted(n for n in os.listdir(mocks_dir) if n.endswith("-mock.html"))
        except OSError:
            mfiles = []
        states = mock_states(mocks_dir, mfiles)
        for fn in mfiles:
            fp = os.path.join(mocks_dir, fn)
            title, desc = scan_mock(fp)
            slug = fn[:-len("-mock.html")]
            mtime = int(os.path.getmtime(fp))
            items.append({
                "type": "mock",
                "id": fn,
                "title": title or humanize(slug),
                "slug": slug,
                "date": time.strftime("%Y-%m-%d", time.localtime(mtime)),
                "status": states.get(fn, ""),
                "description": desc,
                "href": "/_mocks/" + fn,
                "statusHref": "",
                "mtime": mtime,
            })

    items.sort(key=lambda it: (it.get("date") or "", it["mtime"]), reverse=True)
    return items


# ---------------------------------------------------------------------------
# HTML rendering
# ---------------------------------------------------------------------------

def page_shell(title, body, project):
    return (PAGE_TEMPLATE
            .replace("{{TITLE}}", html.escape(title))
            .replace("{{PROJECT}}", html.escape(project))
            .replace("{{BODY}}", body))


def render_markdown_page(rel_path, full_path, project):
    with open(full_path, encoding="utf-8", errors="replace") as f:
        text = f.read()
    fm, _bdy = split_frontmatter(text)
    title = fm.get("name") or humanize(re.sub(r"\.(plan|plan-status)\.md$", "", rel_path))
    status = fm.get("status", "")
    pill = ('<span class="pill pill-status" data-status="%s">%s</span>'
            % (html.escape(status), html.escape(status))) if status else ""
    crumb = ('<div class="crumb"><a href="/">&larr; All plans</a>'
             '<span class="doc-badge">%s</span>%s</div>'
             % ("status ledger" if rel_path.endswith(".plan-status.md") else "plan", pill))
    body = ('<article class="doc">' + crumb
            + '<h1 class="doc-title">' + html.escape(title) + "</h1>"
            + '<div class="md">' + md_to_html(text) + "</div></article>")
    return page_shell(title, body, project)


# ---------------------------------------------------------------------------
# HTTP handler
# ---------------------------------------------------------------------------

class Handler(http.server.SimpleHTTPRequestHandler):
    project = "project"
    mocks_dir = None

    def end_headers(self):
        self.send_header("Cache-Control", "no-store, no-cache, must-revalidate, max-age=0")
        self.send_header("Pragma", "no-cache")
        self.send_header("Expires", "0")
        super().end_headers()

    def log_message(self, *args):
        pass

    def _send(self, body, ctype="text/html; charset=utf-8", code=200):
        data = body.encode("utf-8") if isinstance(body, str) else body
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        if self.command != "HEAD":
            self.wfile.write(data)

    def _send_file(self, fullpath):
        try:
            with open(fullpath, "rb") as f:
                data = f.read()
        except OSError:
            self.send_error(404)
            return
        self.send_response(200)
        self.send_header("Content-Type", self.guess_type(fullpath))
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        if self.command != "HEAD":
            self.wfile.write(data)

    def _serve_mocks(self, path):
        if not self.mocks_dir:
            self.send_error(404, "No mocks directory for this project")
            return
        base = os.path.abspath(self.mocks_dir)
        rel = path[len("/_mocks/"):]
        target = os.path.abspath(os.path.join(base, rel))
        if target != base and not target.startswith(base + os.sep):
            self.send_error(404)
            return
        if os.path.isdir(target):
            idx = os.path.join(target, "index.html")
            if os.path.isfile(idx):
                return self._send_file(idx)
            files = sorted(n for n in os.listdir(target) if n.endswith(".html"))
            links = "".join('<li><a href="/_mocks/%s">%s</a></li>'
                            % (html.escape(f), html.escape(f)) for f in files)
            body = ('<article class="doc"><div class="crumb"><a href="/">&larr; Dashboard</a></div>'
                    '<h1 class="doc-title">Mocks</h1><div class="md"><ul>' + links + "</ul></div></article>")
            return self._send(page_shell("Mocks · " + self.project, body, self.project))
        if os.path.isfile(target):
            return self._send_file(target)
        self.send_error(404)

    def do_GET(self):
        path = self.path.split("?", 1)[0].split("#", 1)[0]

        if path in ("/", "/index", "/_dashboard"):
            return self._send(page_shell("Plans · " + self.project,
                                         DASHBOARD_BODY, self.project))

        if path == "/_api/items.json":
            payload = {"project": self.project,
                       "mocksHref": "/_mocks/" if self.mocks_dir else "",
                       "items": scan(self.directory, self.mocks_dir)}
            return self._send(json.dumps(payload),
                              "application/json; charset=utf-8")

        if path == "/_mocks":
            self.send_response(301)
            self.send_header("Location", "/_mocks/")
            self.end_headers()
            return
        if path.startswith("/_mocks/"):
            return self._serve_mocks(path)

        if path.endswith((".plan.md", ".plan-status.md")):
            rel = path.lstrip("/")
            full = os.path.join(self.directory, rel)
            if os.path.isfile(full) and os.path.abspath(full).startswith(
                    os.path.abspath(self.directory)):
                if "raw" in self.path:
                    return super().do_GET()
                return self._send(render_markdown_page(rel, full, self.project))
            self.send_error(404)
            return

        return super().do_GET()


# ---------------------------------------------------------------------------
# Templates (inlined CSS + JS — fully offline, no Tailwind/CDN needed)
# ---------------------------------------------------------------------------

PAGE_TEMPLATE = """<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{{TITLE}}</title>
<style>
:root{
  --bg:#fafaf9; --panel:#fff; --ink:#1c1917; --muted:#78716c; --line:#e7e5e4;
  --brand:#7c3aed; --brand-soft:#ede9fe; --chip:#f5f5f4; --shadow:0 1px 2px rgba(0,0,0,.05),0 8px 24px rgba(0,0,0,.04);
}
:root.dark{
  --bg:#0c0a09; --panel:#1c1917; --ink:#f5f5f4; --muted:#a8a29e; --line:#292524;
  --brand:#a78bfa; --brand-soft:#2e1065; --chip:#292524; --shadow:0 1px 2px rgba(0,0,0,.4),0 8px 24px rgba(0,0,0,.3);
}
*{box-sizing:border-box}
html{color-scheme:light dark}
body{margin:0;background:var(--bg);color:var(--ink);
  font:15px/1.6 ui-sans-serif,system-ui,-apple-system,"Segoe UI",Roboto,Helvetica,Arial,sans-serif;
  -webkit-font-smoothing:antialiased}
a{color:var(--brand);text-decoration:none}
a:hover{text-decoration:underline}
code{font-family:ui-monospace,SFMono-Regular,Menlo,Consolas,monospace;font-size:.86em;
  background:var(--chip);padding:.12em .38em;border-radius:5px}
.wrap{max-width:1080px;margin:0 auto;padding:28px 20px 80px}
.topbar{display:flex;align-items:center;gap:14px;margin-bottom:22px}
.topbar h1{font-size:18px;margin:0;font-weight:650;letter-spacing:-.01em}
.topbar .sub{color:var(--muted);font-size:13px}
.spacer{flex:1}
.tbtn{border:1px solid var(--line);background:var(--panel);color:var(--ink);
  border-radius:9px;padding:7px 11px;cursor:pointer;font-size:13px}
.tbtn:hover{border-color:var(--brand)}
/* --- dashboard --- */
.toolbar{display:flex;flex-wrap:wrap;gap:10px;align-items:center;margin-bottom:18px}
.search{flex:1;min-width:200px;position:relative}
.search input{width:100%;padding:9px 12px 9px 34px;border:1px solid var(--line);
  border-radius:10px;background:var(--panel);color:var(--ink);font-size:14px}
.search input:focus{outline:none;border-color:var(--brand);box-shadow:0 0 0 3px var(--brand-soft)}
.search svg{position:absolute;left:10px;top:50%;transform:translateY(-50%);color:var(--muted)}
.seg{display:inline-flex;border:1px solid var(--line);border-radius:10px;overflow:hidden;background:var(--panel)}
.seg button{border:0;background:transparent;color:var(--muted);padding:8px 13px;cursor:pointer;font-size:13px}
.seg button[data-on]{background:var(--brand);color:#fff}
select.sort{border:1px solid var(--line);border-radius:10px;background:var(--panel);color:var(--ink);
  padding:8px 11px;font-size:13px}
.count{color:var(--muted);font-size:12.5px;margin:0 0 12px}
.grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(320px,1fr));gap:14px}
.card{background:var(--panel);border:1px solid var(--line);border-radius:14px;padding:16px 17px;
  box-shadow:var(--shadow);display:flex;flex-direction:column;gap:9px;transition:border-color .15s,transform .15s}
.card:hover{border-color:var(--brand);transform:translateY(-1px)}
.card .row1{display:flex;align-items:center;gap:8px}
.badge{font-size:10.5px;font-weight:700;text-transform:uppercase;letter-spacing:.06em;
  padding:3px 8px;border-radius:999px}
.badge-site{background:var(--brand-soft);color:var(--brand)}
.badge-plan{background:var(--chip);color:var(--muted)}
.badge-mock{background:#cffafe;color:#0e7490}
:root.dark .badge-mock{background:#083344;color:#67e8f9}
.card .date{margin-left:auto;color:var(--muted);font-size:12px;font-variant-numeric:tabular-nums}
.card h3{margin:0;font-size:15.5px;font-weight:620;line-height:1.3}
.card h3 a{color:var(--ink)}
.card h3 a:hover{color:var(--brand)}
.card p{margin:0;color:var(--muted);font-size:13px;line-height:1.5;
  display:-webkit-box;-webkit-line-clamp:3;-webkit-box-orient:vertical;overflow:hidden}
.card .meta{display:flex;align-items:center;gap:8px;margin-top:2px;flex-wrap:wrap}
.pill{font-size:11px;font-weight:600;padding:2px 9px;border-radius:999px;background:var(--chip);color:var(--muted)}
.pill-status[data-status="shipped"]{background:#dcfce7;color:#15803d}
.pill-status[data-status="in-progress"]{background:#fef9c3;color:#a16207}
.pill-status[data-status="reviewed"]{background:#dbeafe;color:#1d4ed8}
.pill-status[data-status="draft"]{background:var(--chip);color:var(--muted)}
.pill-status[data-status="superseded"]{background:#fee2e2;color:#b91c1c}
.pill-status[data-status="implemented"]{background:#dcfce7;color:#15803d}
.pill-status[data-status="open"]{background:#fef3c7;color:#b45309}
.pill-status[data-status="chosen"]{background:#ede9fe;color:#6d28d9}
.pill-status[data-status="cancelled"]{background:#e7e5e4;color:#78716c}
:root.dark .pill-status[data-status="shipped"]{background:#052e16;color:#86efac}
:root.dark .pill-status[data-status="in-progress"]{background:#422006;color:#fde047}
:root.dark .pill-status[data-status="reviewed"]{background:#172554;color:#93c5fd}
:root.dark .pill-status[data-status="superseded"]{background:#450a0a;color:#fca5a5}
:root.dark .pill-status[data-status="implemented"]{background:#052e16;color:#86efac}
:root.dark .pill-status[data-status="open"]{background:#422006;color:#fde047}
:root.dark .pill-status[data-status="chosen"]{background:#2e1065;color:#c4b5fd}
:root.dark .pill-status[data-status="cancelled"]{background:#292524;color:#a8a29e}
.statuslink{font-size:12px}
.empty{text-align:center;color:var(--muted);padding:60px 20px}
/* --- rendered markdown doc --- */
.doc{max-width:760px;margin:0 auto}
.crumb{display:flex;align-items:center;gap:10px;margin-bottom:18px;font-size:13px}
.doc-badge{font-size:10.5px;font-weight:700;text-transform:uppercase;letter-spacing:.06em;
  color:var(--brand);background:var(--brand-soft);padding:3px 8px;border-radius:999px}
.doc-title{font-size:30px;font-weight:700;letter-spacing:-.02em;margin:.2em 0 .8em}
.md{font-size:15.5px}
.md h1,.md h2,.md h3{font-weight:650;letter-spacing:-.01em;line-height:1.25;margin:1.6em 0 .5em}
.md h1{font-size:24px} .md h2{font-size:20px;padding-bottom:.25em;border-bottom:1px solid var(--line)}
.md h3{font-size:16.5px}
.md p{margin:.7em 0}
.md ul,.md ol{margin:.6em 0;padding-left:1.5em}
.md li{margin:.25em 0}
.md blockquote{margin:1.1em 0;padding:.7em 1.1em;border-left:3px solid var(--brand);
  background:var(--brand-soft);border-radius:0 8px 8px 0}
.md blockquote p:first-child{margin-top:0}.md blockquote p:last-child{margin-bottom:0}
.md pre{background:var(--chip);padding:14px 16px;border-radius:10px;overflow:auto;border:1px solid var(--line)}
.md pre code{background:none;padding:0;font-size:13px;line-height:1.5}
.md table{border-collapse:collapse;width:100%;margin:1.1em 0;font-size:14px}
.md th,.md td{border:1px solid var(--line);padding:7px 11px;text-align:left;vertical-align:top}
.md th{background:var(--chip);font-weight:600}
.md hr{border:0;border-top:1px solid var(--line);margin:2em 0}
.md a{word-break:break-word}
</style>
</head>
<body>
<div class="wrap">
  <div class="topbar">
    <h1>{{PROJECT}} <span class="sub">· plans</span></h1>
    <div class="spacer"></div>
    <button class="tbtn" data-theme-toggle title="Toggle theme">◐</button>
  </div>
  {{BODY}}
</div>
<script>
(function(){
  var root=document.documentElement, KEY="plans-theme";
  var saved=null; try{saved=localStorage.getItem(KEY)}catch(e){}
  var dark = saved ? saved==="dark"
    : window.matchMedia && window.matchMedia("(prefers-color-scheme: dark)").matches;
  root.classList.toggle("dark", dark);
  var btn=document.querySelector("[data-theme-toggle]");
  if(btn) btn.addEventListener("click",function(){
    var d=root.classList.toggle("dark");
    try{localStorage.setItem(KEY, d?"dark":"light")}catch(e){}
  });
})();
</script>
</body>
</html>
"""

DASHBOARD_BODY = """
<div class="toolbar">
  <div class="search">
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="11" cy="11" r="7"/><path d="M21 21l-4.3-4.3"/></svg>
    <input id="q" type="search" placeholder="Search plans & sites…" autocomplete="off">
  </div>
  <div class="seg" id="filter">
    <button data-f="all" data-on>All</button>
    <button data-f="site">Sites</button>
    <button data-f="plan">Plans</button>
    <button data-f="mock">Mocks</button>
  </div>
  <select class="sort" id="sort">
    <option value="newest">Newest first</option>
    <option value="oldest">Oldest first</option>
    <option value="title">Title A–Z</option>
    <option value="status">Status</option>
    <option value="type">Type</option>
  </select>
  <a class="tbtn" id="mockslink" href="/_mocks/" style="display:none">Mocks ↗</a>
</div>
<p class="count" id="count"></p>
<div class="grid" id="grid"></div>
<script>
(function(){
  var grid=document.getElementById("grid"), countEl=document.getElementById("count");
  var qEl=document.getElementById("q"), sortEl=document.getElementById("sort");
  var filterEl=document.getElementById("filter");
  var ALL=[], filter="all", STATUS_ORDER={draft:0,reviewed:1,"in-progress":2,shipped:3,superseded:4,open:0,chosen:1,implemented:3,cancelled:4};
  function esc(s){return (s||"").replace(/[&<>"]/g,function(c){return {"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;"}[c]})}
  function card(it){
    var badge = '<span class="badge badge-'+it.type+'">'+it.type+'</span>';
    var date = it.date ? '<span class="date">'+esc(it.date)+'</span>' : '<span class="date"></span>';
    var meta = [];
    if(it.type==="site" && it.pages) meta.push('<span class="pill">'+it.pages+' page'+(it.pages>1?'s':'')+'</span>');
    if(it.status) meta.push('<span class="pill pill-status" data-status="'+esc(it.status)+'">'+esc(it.status)+'</span>');
    if(it.statusHref) meta.push('<a class="statuslink" href="'+esc(it.statusHref)+'">status ledger ↗</a>');
    var metaHtml = meta.length ? '<div class="meta">'+meta.join("")+'</div>' : '';
    var descHtml = it.description ? '<p>'+esc(it.description)+'</p>' : '';
    return '<div class="card">'
      + '<div class="row1">'+badge+date+'</div>'
      + '<h3><a href="'+esc(it.href)+'">'+esc(it.title)+'</a></h3>'
      + descHtml + metaHtml + '</div>';
  }
  function render(){
    var q=qEl.value.trim().toLowerCase();
    var list=ALL.filter(function(it){
      if(filter!=="all" && it.type!==filter) return false;
      if(!q) return true;
      return (it.title+" "+it.slug+" "+(it.description||"")+" "+(it.status||"")).toLowerCase().indexOf(q)>=0;
    });
    var s=sortEl.value;
    list.sort(function(a,b){
      if(s==="title") return a.title.localeCompare(b.title);
      if(s==="type") return a.type.localeCompare(b.type) || (b.date||"").localeCompare(a.date||"");
      if(s==="status") return (STATUS_ORDER[b.status]||-1)-(STATUS_ORDER[a.status]||-1) || (b.date||"").localeCompare(a.date||"");
      var d=(a.date||"")<(b.date||"")?-1:(a.date||"")>(b.date||"")?1:0;
      return s==="oldest"? d : -d;
    });
    countEl.textContent = list.length+" of "+ALL.length+" item"+(ALL.length===1?"":"s");
    grid.innerHTML = list.length ? list.map(card).join("")
      : '<div class="empty">No plans or plan-sites match.</div>';
  }
  qEl.addEventListener("input",render);
  sortEl.addEventListener("change",render);
  filterEl.addEventListener("click",function(e){
    var b=e.target.closest("button"); if(!b) return;
    filter=b.getAttribute("data-f");
    [].forEach.call(filterEl.children,function(c){c.toggleAttribute("data-on",c===b)});
    render();
  });
  fetch("/_api/items.json").then(function(r){return r.json()}).then(function(d){
    ALL=d.items||[];
    if(d.mocksHref){var ml=document.getElementById("mockslink"); ml.href=d.mocksHref; ml.style.display="";}
    render();
  }).catch(function(){ grid.innerHTML='<div class="empty">Could not load items.</div>'; });
})();
</script>
"""


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def main(argv):
    if argv and argv[0] in ("--ensure-port", "--base-port"):
        plans_dir = argv[1] if len(argv) > 1 else default_plans_dir()
        print(ensure_port(plans_dir) if argv[0] == "--ensure-port"
              else base_port(plans_dir))
        return

    port = int(argv[0]) if argv and argv[0].isdigit() else None
    plans_dir = (argv[1] if len(argv) > 1 else
                 (argv[0] if argv and not argv[0].isdigit() else default_plans_dir()))
    plans_dir = os.path.abspath(plans_dir)
    if port is None:
        port = ensure_port(plans_dir)

    Handler.project = os.path.basename(os.path.dirname(plans_dir)) or "project"
    Handler.mocks_dir = find_mocks_dir(os.path.dirname(plans_dir))
    handler = partial(Handler, directory=plans_dir)
    socketserver.TCPServer.allow_reuse_address = True
    with socketserver.TCPServer(("0.0.0.0", port), handler) as httpd:
        print("  Plans dashboard: http://localhost:%d/  (serving %s)" % (port, plans_dir))
        if Handler.mocks_dir:
            print("  Mocks:           http://localhost:%d/_mocks/  (from %s)" % (port, Handler.mocks_dir))
        httpd.serve_forever()


if __name__ == "__main__":
    main(sys.argv[1:])
