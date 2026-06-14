# {{REPORT_TITLE}} ({{DATE}})

{{ONE_PARAGRAPH_WHAT_THIS_IS}}

## View it

```bash
./serve.sh            # serves on http://localhost:8920/  (pass a port to override)
```

The bundle is **standalone** — Tailwind is vendored into `assets/tailwind.css`, so there
are no CDN or network dependencies at view time. After editing any page that introduces
new utility classes, recompile:

```bash
./build-css.sh        # rescans every .html here and rewrites assets/tailwind.css
```

## The pages

| Page | What |
|------|------|
| `index.html` | {{OVERVIEW_DESC}} |
| `page-two.html` | {{PAGE_TWO_DESC}} |

## Provenance

{{WHERE_THE_CONTENT_CAME_FROM — evidence, citations, prior plans/handoffs}}
