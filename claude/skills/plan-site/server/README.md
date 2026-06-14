# Plan dashboard server (per project)

One server hosts **every** plan-site and `.plan.md` in this project's `plans/`
directory. It replaces the old "one pm2 process + one port per plan-site".

This folder is copied into a project as `plans/_server/` and is self-contained
(stdlib Python only, no network at view time) — tweak it per project if you want.

## Run it

```bash
./ensure.sh            # start-or-reuse the project's server, print the dashboard URL
./ensure.sh --restart  # restart after editing plans_server.py
```

`ensure.sh` registers the server under pm2 as `<project>-plans` on a stable
per-project port (deterministic from the path, recorded in `.port`), and is
idempotent — running it again reuses the existing process instead of spawning a
duplicate.

## What it serves

| Route | What |
|-------|------|
| `/` | The dashboard — every site + every plan, with live search / sort / filter (sites · plans · both) |
| `/_api/items.json` | The discovered items as JSON (the dashboard's data source; also handy for a cross-project view) |
| `/<YYYY-MM-DD-slug>/` | A plan-site, served as static files (untouched) |
| `/<name>.plan.md` | A markdown plan, rendered to a themed HTML page (`?raw` for the source) |
| `/<name>.plan-status.md` | The as-built ledger, rendered the same way |
| `/_mocks/` | The project's `ui-mockups` directory (served from outside `plans/`); `/_mocks/` is its index |

Discovery is **dynamic** — `plans/` is rescanned on every request, so new plans
and sites show up on a plain refresh. There is no index file to regenerate.

## How items are discovered

- **plan-site** = a `YYYY-MM-DD-<slug>/` directory containing `index.html`.
  Metadata comes from `meta.json` if present (`{title, description, date}`),
  otherwise it's scraped from the page `<title>` / `<meta description>` / lede.
- **plan** = a `*.plan.md` file. Title/date/status come from its frontmatter and
  the description from its `> TL;DR` `**What:**` line. A matching
  `*.plan-status.md` is linked from the card.
- Anything named `_*` or `.*` (like this `_server/` folder) is ignored.
- **mock** = a `*-mock.html` file in the project's `ui-mockups` directory (which is
  *outside* `plans/`). Auto-detected from common locations, or set explicitly with
  `_server/config.json` → `{"mocksDir": "frontend/public/mocks"}` (path relative to the
  project root, or absolute). The lifecycle badge is best-effort scraped from the mocks
  `index.html`; mock dirs that don't use the standard lifecycle badges just list without one.
