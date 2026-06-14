/* Report chrome — all dependency-free, offline, no framework.
   Renders the "Spine" sidebar from the SITE_NAV manifest (so page numbers,
   grouping and the current-page mark are DERIVED, never hand-typed), runs a
   robust position-based scroll-spy, drives the mobile bar / bottom sheet /
   drawer, the press-/ quick-jump, the theme toggle, reveal-on-scroll, and the
   before/after image slider.

   The author writes: site-nav.js (the outline, once) + each page's <main>
   sections as <section id data-toc="Label">…</section>. This script builds the
   rest. See SKILL.md "page anatomy". */
(function () {
  "use strict";
  const root = document.documentElement;
  const PRM = window.matchMedia("(prefers-reduced-motion: reduce)");
  const pad2 = (n) => String(n).padStart(2, "0");
  const esc = (s) => String(s).replace(/[&<>"]/g, (c) =>
    ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" }[c]));

  // ---- Theme (persisted; shared key so embeds can follow) -----------------
  const TKEY = "plan-site-theme";
  function applyTheme(t) {
    root.classList.toggle("dark", t === "dark");
    document.querySelectorAll("[data-theme-label]").forEach((el) => {
      el.textContent = t === "dark" ? "Dark" : "Light";
    });
  }
  let theme = localStorage.getItem(TKEY) ||
    (window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light");
  applyTheme(theme);
  document.addEventListener("click", (e) => {
    if (!e.target.closest("[data-theme-toggle]")) return;
    theme = root.classList.contains("dark") ? "light" : "dark";
    localStorage.setItem(TKEY, theme);
    applyTheme(theme);
  });

  // ---- The outline (manifest → derived pages) -----------------------------
  const NAV = window.SITE_NAV || { report: document.title, logo: "", groups: [] };
  const here = ((location.pathname.split("/").pop() || "index.html").toLowerCase()) || "index.html";
  const norm = (f) => (f || "").toLowerCase().replace(/^\.\//, "") || "index.html";
  const pages = [];
  let n = 0, lastGroup = undefined;
  (NAV.groups || []).forEach((g) => (g.pages || []).forEach((p) => {
    n += 1;
    pages.push({ n, file: p.file, title: p.title, group: g.label,
      groupStart: g.label !== lastGroup, current: norm(p.file) === here });
    lastGroup = g.label;
  }));
  const total = pages.length;
  const cur = pages.find((p) => p.current) || pages[0] || { n: 1, title: NAV.report };

  // This page's sections, read from the page body (id + data-toc).
  const main = document.querySelector("[data-main]") || document.querySelector("main") || document;
  const secEls = Array.from(main.querySelectorAll("[id][data-toc]"));
  const secs = secEls.map((el) => ({ id: el.id, toc: el.getAttribute("data-toc") }));

  // ---- Render the brand ---------------------------------------------------
  document.querySelectorAll("[data-brand]").forEach((b) => {
    b.innerHTML =
      `<span class="ps-mark">${esc(NAV.logo || "")}</span>` +
      `<span class="ps-brandtext"><span class="ps-report">${esc(NAV.report || "")}</span>` +
      (NAV.tagline ? `<span class="ps-tagline">${esc(NAV.tagline)}</span>` : "") + `</span>`;
  });

  // ---- Render the Spine tree ----------------------------------------------
  // Pages hang off one rail; the current page expands to show its sections
  // (nested on a sub-rail with a sliding marker + scroll-progress fill).
  function treeHTML() {
    let h = "";
    pages.forEach((p) => {
      if (p.groupStart && p.group) h += `<p class="ps-grp">${esc(p.group)}</p>`;
      h += `<a class="ps-page${p.current ? " is-current" : ""}" href="./${esc(p.file)}"` +
           (p.current ? ' aria-current="page"' : "") + `>` +
           `<span class="ps-num">${pad2(p.n)}</span><span class="ps-ptitle">${esc(p.title)}</span></a>`;
      if (p.current && secs.length) {
        h += `<div class="ps-subs"><span class="ps-fill" data-fill></span><span class="ps-marker" data-marker></span>`;
        secs.forEach((s) => {
          h += `<a class="ps-sub" href="#${esc(s.id)}" data-spy="${esc(s.id)}">${esc(s.toc)}</a>`;
        });
        h += `</div>`;
      }
    });
    return h;
  }
  const navEl = document.querySelector("[data-nav]");
  if (navEl) navEl.innerHTML = treeHTML();

  document.querySelectorAll("[data-meter]").forEach((m) => {
    m.innerHTML = `<span class="ps-pageof">Page ${cur.n} of ${total}</span>` +
      `<span class="ps-track"><i style="width:${total ? (cur.n / total) * 100 : 0}%"></i></span>`;
  });

  // ---- Inject mobile overlays + quick-jump (once) -------------------------
  const body = document.body;
  const overlay = document.createElement("div");
  overlay.innerHTML = `
    <div class="ps-backdrop" data-backdrop hidden></div>
    <aside class="ps-drawer" data-drawer hidden role="dialog" aria-modal="true" aria-label="All pages">
      <div class="ps-brand" data-brand></div>
      <nav class="ps-nav" data-drawernav aria-label="Contents"></nav>
    </aside>
    <div class="ps-sheet" data-sheet hidden role="dialog" aria-modal="true" aria-label="On this page">
      <div class="ps-grab"></div>
      <p class="ps-shead">On this page <span>· Page ${cur.n} of ${total}</span></p>
      <nav data-sheetnav></nav>
    </div>
    <div class="ps-qj" data-qj hidden role="dialog" aria-modal="true" aria-label="Jump to">
      <div class="ps-qj-scrim" data-qjscrim></div>
      <div class="ps-qj-box">
        <input type="text" class="ps-qj-input" data-qjinput placeholder="Jump to a page or section…" aria-label="Search pages and sections" />
        <div class="ps-qj-results" data-qjresults role="listbox"></div>
      </div>
    </div>`;
  body.appendChild(overlay);
  // brand inside drawer
  overlay.querySelector("[data-drawer] [data-brand]").innerHTML =
    document.querySelector("[data-brand]") ? document.querySelector("[data-brand]").innerHTML : "";
  overlay.querySelector("[data-drawernav]").innerHTML = treeHTML();
  overlay.querySelector("[data-sheetnav]").innerHTML =
    secs.map((s) => `<a href="#${esc(s.id)}" data-spy="${esc(s.id)}">${esc(s.toc)}</a>`).join("");

  // ---- Robust scroll-spy (position-computed; no dead band) ---------------
  // active = last section past a line 30% down the viewport, clamped to first
  // at the top and last at the bottom → always exactly one, including ends.
  const spySections = secs.map((s) => document.getElementById(s.id)).filter(Boolean);
  const marker = navEl ? navEl.querySelector("[data-marker]") : null;
  const fill = navEl ? navEl.querySelector("[data-fill]") : null;
  const subsEl = navEl ? navEl.querySelector(".ps-subs") : null;
  if (marker) marker.style.top = "0px";

  function setActive(id, frac) {
    document.querySelectorAll("[data-spy]").forEach((a) => {
      const on = a.getAttribute("data-spy") === id;
      a.setAttribute("data-active", on ? "true" : "false");
      if (on) a.setAttribute("aria-current", "location"); else a.removeAttribute("aria-current");
    });
    if (marker && subsEl) {
      const act = navEl.querySelector(`.ps-sub[data-spy="${CSS.escape(id)}"]`);
      if (act) marker.style.transform = `translateY(${act.offsetTop + act.offsetHeight / 2 - 9}px)`;
      if (fill) fill.style.height = Math.max(0, frac * (subsEl.clientHeight - 16)) + "px";
    }
    const s = secs.find((x) => x.id === id);
    document.querySelectorAll("[data-here]").forEach((e) => { if (s) e.textContent = s.toc; });
    document.querySelectorAll("[data-progress]").forEach((e) => { e.style.width = (frac * 100) + "%"; });
  }

  if (spySections.length) {
    const ACT = 0.30, EPS = 2;
    let tops = [];
    const measure = () => { tops = spySections.map((s) => s.offsetTop); };
    function compute() {
      const sy = window.scrollY || root.scrollTop;
      const vh = window.innerHeight, docH = root.scrollHeight;
      const frac = Math.max(0, Math.min(1, sy / Math.max(1, docH - vh)));
      let active = spySections[0];
      if (sy + vh >= docH - EPS) active = spySections[spySections.length - 1];
      else { const line = sy + vh * ACT; for (let i = 0; i < spySections.length; i++) {
        if (tops[i] <= line) active = spySections[i]; else break; } }
      return { id: active.id, frac };
    }
    let ticking = false;
    const sync = () => { const r = compute(); setActive(r.id, r.frac); };
    const onScroll = () => { if (ticking) return; ticking = true;
      requestAnimationFrame(() => { ticking = false; sync(); }); };
    measure();
    window.addEventListener("scroll", onScroll, { passive: true });
    window.addEventListener("resize", () => { measure(); sync(); });
    // IO is only a "something changed, recompute" trigger — the decision is
    // always positional, so it can never dead-zone.
    const io = new IntersectionObserver(() => sync(), { threshold: 0 });
    spySections.forEach((s) => io.observe(s));
    requestAnimationFrame(() => { measure(); sync(); });
    window.addEventListener("load", () => { measure(); sync(); });
  }

  // ---- Mobile drawer / bottom sheet (focus-trapped dialogs) --------------
  const backdrop = overlay.querySelector("[data-backdrop]");
  const drawer = overlay.querySelector("[data-drawer]");
  const sheet = overlay.querySelector("[data-sheet]");
  const qj = overlay.querySelector("[data-qj]");
  let openEl = null, lastFocus = null;
  const focusables = (el) => Array.from(el.querySelectorAll(
    'a[href],button,input,[tabindex]:not([tabindex="-1"])')).filter((n) => n.offsetParent !== null);

  function openDialog(el, toggle) {
    lastFocus = document.activeElement;
    backdrop.hidden = false; el.hidden = false; openEl = el;
    body.style.overflow = "hidden";
    if (toggle) toggle.setAttribute("aria-expanded", "true");
    const f = focusables(el); (f[0] || el).focus && (f[0] || el).focus();
  }
  function closeDialog() {
    if (!openEl) return;
    backdrop.hidden = true; openEl.hidden = true; openEl = null;
    body.style.overflow = "";
    document.querySelectorAll('[aria-expanded="true"]').forEach((b) => b.setAttribute("aria-expanded", "false"));
    if (lastFocus && lastFocus.focus) lastFocus.focus();
  }
  document.addEventListener("click", (e) => {
    const navT = e.target.closest("[data-nav-toggle]");
    const sheetT = e.target.closest("[data-sheet-toggle]");
    const jumpT = e.target.closest("[data-jump]");
    if (navT) { e.preventDefault(); openEl === drawer ? closeDialog() : (closeDialog(), openDialog(drawer, navT)); return; }
    if (sheetT) { e.preventDefault(); openEl === sheet ? closeDialog() : (closeDialog(), openDialog(sheet, sheetT)); return; }
    if (jumpT) { e.preventDefault(); openQuickJump(); return; }
    if (e.target.closest("[data-backdrop],[data-qjscrim]")) { closeDialog(); closeQuickJump(); return; }
    if (openEl && e.target.closest("[data-drawer] a, [data-sheet] a")) closeDialog();
  });
  document.addEventListener("keydown", (e) => {
    if (e.key === "Escape") { closeDialog(); closeQuickJump(); return; }
    if (e.key === "Tab" && openEl) {
      const f = focusables(openEl); if (!f.length) return;
      const first = f[0], last = f[f.length - 1];
      if (e.shiftKey && document.activeElement === first) { e.preventDefault(); last.focus(); }
      else if (!e.shiftKey && document.activeElement === last) { e.preventDefault(); first.focus(); }
    }
  });
  window.matchMedia("(min-width: 1024px)").addEventListener("change", (e) => { if (e.matches) closeDialog(); });

  // ---- Quick-jump (press /) ----------------------------------------------
  const index = [
    ...pages.map((p) => ({ type: "Page", label: p.title, sub: p.group || "", href: "./" + p.file, id: null })),
    ...secs.map((s) => ({ type: "Section", label: s.toc, sub: cur.title, href: "#" + s.id, id: s.id })),
  ];
  const qjInput = qj.querySelector("[data-qjinput]");
  const qjResults = qj.querySelector("[data-qjresults]");
  let qjShown = [], qjSel = 0;
  function qjRender(q) {
    q = q.trim().toLowerCase();
    qjShown = index.filter((r) => !q || r.label.toLowerCase().includes(q) || r.sub.toLowerCase().includes(q));
    qjSel = 0;
    qjResults.innerHTML = qjShown.length ? qjShown.map((r, i) =>
      `<div class="ps-qj-res" role="option" data-i="${i}" aria-selected="${i === 0}">` +
      `<span class="ps-qj-tag">${r.type}</span><span class="ps-qj-lbl">${esc(r.label)}</span>` +
      `<span class="ps-qj-sub">${esc(r.sub || "—")}</span></div>`).join("")
      : `<div class="ps-qj-empty">No matches</div>`;
  }
  function qjMove(d) {
    if (!qjShown.length) return;
    qjSel = (qjSel + d + qjShown.length) % qjShown.length;
    qjResults.querySelectorAll(".ps-qj-res").forEach((e, i) => e.setAttribute("aria-selected", i === qjSel ? "true" : "false"));
    const el = qjResults.querySelector(`[data-i="${qjSel}"]`); if (el) el.scrollIntoView({ block: "nearest" });
  }
  function qjChoose(i) {
    const r = qjShown[i]; if (!r) return; closeQuickJump();
    if (r.id) { const t = document.getElementById(r.id); if (t) t.scrollIntoView({ behavior: PRM.matches ? "auto" : "smooth" }); }
    else location.href = r.href;
  }
  function openQuickJump() {
    closeDialog(); lastFocus = document.activeElement;
    qj.hidden = false; backdrop.hidden = true; body.style.overflow = "hidden";
    qjInput.value = ""; qjRender(""); qjInput.focus();
  }
  function closeQuickJump() {
    if (qj.hidden) return; qj.hidden = true; body.style.overflow = "";
    if (lastFocus && lastFocus.focus) lastFocus.focus();
  }
  qjInput.addEventListener("input", (e) => qjRender(e.target.value));
  qjInput.addEventListener("keydown", (e) => {
    if (e.key === "ArrowDown") { e.preventDefault(); qjMove(1); }
    else if (e.key === "ArrowUp") { e.preventDefault(); qjMove(-1); }
    else if (e.key === "Enter") { e.preventDefault(); qjChoose(qjSel); }
    else if (e.key === "Tab") { e.preventDefault(); qjMove(e.shiftKey ? -1 : 1); }
  });
  qjResults.addEventListener("click", (e) => { const r = e.target.closest("[data-i]"); if (r) qjChoose(+r.dataset.i); });
  document.addEventListener("keydown", (e) => {
    if (e.key === "/" && qj.hidden && !/^(INPUT|TEXTAREA|SELECT)$/.test(document.activeElement.tagName) && !document.activeElement.isContentEditable) {
      e.preventDefault(); openQuickJump();
    }
  });

  // ---- Reveal on scroll ---------------------------------------------------
  const revealer = new IntersectionObserver((entries, obs) => {
    entries.forEach((en) => { if (en.isIntersecting) { en.target.classList.add("in"); obs.unobserve(en.target); } });
  }, { rootMargin: "0px 0px -8% 0px" });
  document.querySelectorAll(".reveal").forEach((el) => revealer.observe(el));

  // ---- Before/after image slider -----------------------------------------
  document.querySelectorAll("[data-slider]").forEach((wrap) => {
    const after = wrap.querySelector(".slider-after");
    const handle = wrap.querySelector(".slider-handle");
    if (!after || !handle) return;
    const setPct = (pct) => { pct = Math.max(0, Math.min(100, pct)); after.style.width = pct + "%"; handle.style.left = pct + "%"; };
    setPct(50);
    let dragging = false;
    const fromEvent = (e) => { const rect = wrap.getBoundingClientRect();
      const x = (e.touches ? e.touches[0].clientX : e.clientX) - rect.left; setPct((x / rect.width) * 100); };
    wrap.addEventListener("mousedown", (e) => { dragging = true; fromEvent(e); });
    wrap.addEventListener("touchstart", (e) => { dragging = true; fromEvent(e); }, { passive: true });
    window.addEventListener("mousemove", (e) => { if (dragging) fromEvent(e); });
    window.addEventListener("touchmove", (e) => { if (dragging) fromEvent(e); }, { passive: true });
    window.addEventListener("mouseup", () => { dragging = false; });
    window.addEventListener("touchend", () => { dragging = false; });
  });

  // ---- Debug overlay — name every part (precise UI iteration) -------------
  // When a page embeds a UI demo, tag content parts with data-dbg="<name>"
  // (leaf) and groups with data-dbgc="<name>" (container), named the way the
  // user would say them. This adds a fixed toggle that overlays each part with
  // its name, so "make the depth-score bigger" beats "the thing under the
  // title". The toggle only appears when the page actually has tagged parts;
  // ?dbg in the URL force-enables it (handy for screenshots). Labels live in a
  // JS top layer (a CSS ::after would be clipped to nothing by overflow:hidden
  // on clamped text / rounded thumbnails); only the dashed outline is CSS.
  if (document.querySelector("[data-dbg],[data-dbgc]")) {
    const bar = document.createElement("div");
    bar.className = "ps-dbgbar";
    bar.innerHTML = `<label><input type="checkbox" id="ps-dbgtoggle"> <span>🔍 Debug overlay</span></label>`;
    body.appendChild(bar);
    const cb = bar.querySelector("#ps-dbgtoggle");
    function dbgRender() {
      document.querySelectorAll(".ps-dbg-label").forEach((e) => e.remove());
      if (!body.classList.contains("dbg")) return;
      const sx = window.scrollX, sy = window.scrollY;
      document.querySelectorAll("[data-dbg],[data-dbgc]").forEach((el) => {
        const c = el.hasAttribute("data-dbgc");
        const name = c ? el.dataset.dbgc : el.dataset.dbg;
        const r = el.getBoundingClientRect(); if (!r.width || !r.height) return;
        const l = document.createElement("div");
        l.className = "ps-dbg-label" + (c ? " c" : ""); l.textContent = name;
        l.style.top = (sy + r.top) + "px"; l.style.left = (sx + (c ? r.right : r.left)) + "px";
        body.appendChild(l);
      });
    }
    function dbgSet(on) { body.classList.toggle("dbg", on); cb.checked = on; dbgRender(); }
    cb.addEventListener("change", (e) => dbgSet(e.target.checked));
    if (/[?&]dbg\b/.test(location.search)) dbgSet(true);
    window.addEventListener("scroll", dbgRender, true);
    window.addEventListener("resize", dbgRender);
  }
})();
