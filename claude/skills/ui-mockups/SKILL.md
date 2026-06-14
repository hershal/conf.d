---
name: ui-mockups
description: Create static HTML UI mockups that present design options side by side so a variant can be chosen before any production code is written, and maintain a stateful mocks index that tracks each mock through its lifecycle (open → chosen → implemented / cancelled). Use whenever the user asks to mock up, prototype, or explore design options for a UI change before building it.
---

# UI mockups

A UI mock is a **decision artifact**: a single static, dependency-free HTML page that shows today's UI plus a few proposed alternatives side by side, so a human can pick one *before* any framework code is written. Mocks are cheap to make, cheap to throw away, and they make a design choice explicit, reviewable, and revisitable.

This skill is the stack-agnostic **methodology**. A project may ship a companion **profile** that pins the concrete stack — theme tokens, dev URL/port, component-fidelity classes, real data sources, build/restart quirks. The profile is a separate skill named for the project (e.g. `ui-mockups-<project>`) because a personal skill and a project skill *cannot share a name* — in Claude Code a personal skill silently shadows a same-named project one. So:

> **Before mocking, look for a project profile** (a `ui-mockups-<project>` skill, or a `.claude/skills/*mockup*/` file). If one exists, **read it and let it override every concrete detail below** — tokens, URLs, fidelity classes. This file owns the *method*; the profile owns the *specifics*.

## Core principles

1. **One page per decision.** Each mock answers one design question. Don't bundle unrelated changes into one page.
2. **Baseline first.** The first variant always reproduces **today's UI** verbatim, labeled `0. Current` (or `1A. Current baseline`). A reviewer can't judge a change they can't compare against.
3. **Recommend, with a reason.** Mark one variant `(recommended)` and justify it in a one-line rationale. A mock that presents options without a point of view pushes the decision back onto the user uselessly.
4. **Real content, never lorem ipsum.** Use realistic, domain-accurate data — real-looking names, titles, numbers, states. Placeholder text hides density and wrapping problems that are the whole point of a mock.
5. **Static and dependency-free.** One self-contained `.html` file. Inline the theme; pull styling from a CDN if you must (e.g. Tailwind via `<script src>`), but no build step, no local imports, no JS framework. It must open by double-click.
6. **Mirror the real components exactly.** Copy the actual class names / markup from the source so the mock can't drift from production. A mock that *looks* like the app but isn't built from its real classes will mislead the decision. (The project profile lists the exact classes to copy.)
7. **Don't implement until a variant is chosen.** Mocks exist to *get* a decision, not to *announce* one. Build only after the user picks — and then record the pick in the index (see lifecycle).

## Where mocks live & the index

- All mocks live in **one directory** (the profile names it; commonly `web/public/mocks/` or `docs/mocks/`), served by the dev server so the user can open them in a browser.
- **`index.html` in that directory is the dashboard.** Every mock MUST be listed there, and every entry MUST carry a state badge (below). The index is a **flat list, newest first.**
- File naming: `<kebab-slug>-mock.html`.
- Never edit build artifacts (e.g. anything under `.next/`, `dist/`).

## The mock lifecycle — required

This is the core of the skill. Every entry in the index carries **exactly one state**, shown as a colored badge. The set is deliberately small:

| State | Meaning | Badge | Driven by |
|---|---|---|---|
| **open** | Variants presented; **no variant chosen yet.** The default for every new mock. | amber | set at creation |
| **chosen** | A variant has been **picked but not yet built.** | purple | the agent that records the user's pick |
| **implemented** | The chosen variant has **shipped to code.** *Terminal.* | green | the agent that ships it — flip it in the **same change** |
| **cancelled** | **Abandoned**, superseded by another mock, or made obsolete. *Terminal.* | gray | when the idea is dropped/superseded |

Think of it as two **active** states (open, chosen) and two **closed/terminal** states (implemented, cancelled).

**Governing rule — only define states a real moment reliably drives.** (Same discipline as the handoff/closeout status lifecycles.) Each transition above corresponds to a concrete moment an agent reliably acts: creation, recording a pick, shipping the change, dropping the idea. There is deliberately **no "in-progress" state** — no agent reliably flips it, so it would rot. A status nobody updates is worse than no status. When you act on a mock, move its badge in the same change:

- **You build a chosen variant** → flip that mock to **implemented** in the same commit. (Don't leave shipped designs sitting at `open`/`chosen` — a stale `open` badge is a standing, false invitation to re-decide a settled thing.)
- **The user picks a variant but you're not building yet** → flip to **chosen** and note which variant.
- **A mock is dropped or replaced by a newer one** → flip to **cancelled** and say why / point at the successor.
- **Don't reorder on state change.** The list stays newest-first; only the badge (and optionally a faded treatment for cancelled) changes.

When unsure whether something shipped, **check the source** before stamping `implemented` — the badge claims the design is live, so it needs evidence (a file:line where the real UI matches the chosen variant), not a guess.

## Index maintenance (every time you add or touch a mock)

1. **Add new cards at the TOP** of the list (newest first).
2. Give every card a **category chip**, a **creation date**, and a **state badge** (default `open` for a new one).
3. **De-emphasize as state advances**: `open` cards get a subtle accent border so undecided work stands out; `implemented`/`cancelled` cards get a neutral border (cancelled may also be dimmed). The badge is the source of truth either way.
4. Keep the header **state legend** and the footer **count** (`N prototypes · X open · Y implemented`) accurate.
5. When a variant is chosen or shipped, update the card's **description** too: prefix or suffix with the decision (e.g. `Chosen: 1B` / `Implemented — <variant>`), and **fix any stale "recommended" label** so the card matches the mock body. Do **not** move the card.

## Page template

Every mock page is one self-contained file. Replace the theme block with the **project's actual tokens** (the profile lists them; otherwise copy them from the app's global stylesheet):

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Mock — [Description]</title>
  <!-- CDN styling is fine; no build step. -->
  <style>
    :root { /* paste the project's theme tokens here, verbatim */ }
    body { /* app background/foreground/font */ }
    a { color: inherit; }
  </style>
</head>
<body>
  <div class="container">
    <header>
      <h1>[Page title]</h1>
      <p>[One sentence: what is being compared and why.]</p>
      <p>Back to <a href="index.html">mocks index</a></p>
    </header>

    <!-- 0. Current baseline — reproduce today's UI verbatim -->
    <section>
      <p class="variant-label">0. Current baseline</p>
      <!-- real component markup copied from source -->
    </section>

    <!-- 1B, 1C … one proposed option each -->
    <section>
      <p class="variant-label">1B. Option name — short gist (recommended)</p>
      <p class="rationale">Rationale: trade-offs, why this is recommended (or not).</p>
      <!-- proposed markup -->
    </section>
  </div>
</body>
</html>
```

## Table of contents — required

Every mock has multiple stacked sections (baseline, variants, galleries, critique), so **give each page a table of contents** near the top: a compact row of anchor links to each section. Add an `id` to every section heading and link to it. It makes a long decision page navigable and lets the user (and you) jump straight to "the rating gallery" or "the interactive row".

```html
<nav class="toc" aria-label="Contents">
  <span class="toc-h">On this page</span>
  <a href="#baseline">Baseline</a><a href="#opt-1b">1B · …</a><a href="#critique">Critique</a>
</nav>
<style>
.toc{display:flex;flex-wrap:wrap;align-items:center;gap:6px 12px;margin-top:16px;padding:10px 14px;border:1px solid var(--border);border-radius:10px;background:var(--card);font-size:12.5px;}
.toc-h{font-size:10.5px;text-transform:uppercase;letter-spacing:.06em;color:var(--muted);font-weight:700;}
.toc a{color:var(--accent);}
</style>
```

## Make it interactive — live playgrounds (the user loves these)

**Strong, repeatedly-confirmed user preference: mocks should be *interactable*, not just static galleries.** Whenever the thing being designed has *behavior* — anything that animates, appears/disappears, changes state on input, or is felt as much as seen — build a **live playground** into the mock: real controls (buttons, toggles, segmented switches, sliders) that fire the actual component so the user can *play with it*, not just look at a frozen picture. A toast that slides in, a gesture with tunable resistance, a button that morphs on click, a filter that re-sorts a list — a static screenshot undersells all of them; let the user trigger the real motion. This is dependency-free vanilla JS in a page-scoped `<script>` (the "static and dependency-free" principle means *no build step / no framework*, **not** "no JavaScript").

Patterns that have landed well:
- **A control panel that drives the real component.** Pick a variant + state from segmented switches, toggle options (has-action? long-text?), then a **Fire / Run / Play** button mounts the live component with its true enter/exit animation. Add a "fire 3" / "stack" button when concurrent behavior matters.
- **Tunable knobs** for anything with feel (gesture resistance, timing, thresholds): live sliders + presets + a copyable resulting config, so the user dials in the values you'll then bake into code.
- **Still keep the static galleries too.** They're what a screenshot captures and what the decision rests on; the playground is the *added* dimension. Galleries for at-a-glance comparison, playground for the live feel.
- Gate motion-heavy demos behind `prefers-reduced-motion` where it matters, and make controls keyboard-reachable.

If a design has no dynamic behavior at all (a pure layout/spacing/color choice), a playground adds nothing — don't force one. But the moment there's motion or state, reach for it by default.

## Responsive mocks: render at true device widths

If a component re-lays-out across breakpoints, **do not** show it in a single narrow column — that clips wider layouts to the mock's own width and hides exactly what you're trying to judge. Instead:

- Render each breakpoint in its **own fixed-width frame** at the **true device width** (e.g. ~390px mobile, ~834px tablet, ~1280px desktop), each in its own horizontally-scrollable box.
- Prefer **one container-query template per variant** that re-flows by its container's width, then drop that single template into each device frame — so the mock proves the *same* markup adapts, rather than hand-faking three layouts.
- Label each frame with its width.

## Debug overlay — name every part (so iteration is precise)

Iterating on a mock over chat is far faster when **every part has a name** both sides can point at — "make the *depth-score* bigger", "move *rating* next to *flag*", "drop the *rail*". Build this into every non-trivial mock: a toggle that overlays each region with its name. It turns vague back-and-forth ("the thing under the title") into precise edits.

**Convention.** Tag content-bearing parts with `data-dbg="<name>"` (leaf — e.g. `title`, `summary`, `rating`, `flag`) and structural groups with `data-dbgc="<name>"` (container — e.g. `row`, `action-bar`, `tags`). Name parts the way the **user would say them**, not the CSS class. Don't label pure wrappers that have no meaning of their own — a bare `body`/`meta` wrapper shown in the overlay just reads as a confusing **empty box**; label the meaningful thing inside it instead (e.g. the byline), or leave it unlabelled.

**Render labels in a JS top layer — NOT as CSS `::after` pseudo-elements.** This is the one real gotcha, and it fails silently: the parts you most want to name — clamped titles/summaries (`overflow:hidden` + `-webkit-line-clamp`) and rounded thumbnails (`overflow:hidden`) — will **clip a pseudo-element label to nothing**, so exactly those labels vanish with no error. A separate absolutely-positioned layer can't be clipped by the element's own overflow. Keep the dashed `outline` in CSS (an `outline` is drawn outside the box and is *not* clipped by the element's overflow); put only the text label in the JS layer, positioned from each element's `getBoundingClientRect()`.

**Make the toggle a fixed, always-reachable control** — `position:fixed` (a floating pill or FAB in a corner) so it stays clickable no matter how far the page is scrolled. A toggle that scrolls off the top is useless on a long mock. Placement is a project taste call (top-right pill, bottom-right FAB, bottom-center bar…); **top-right pill is the default**.

Drop-in (fixed toggle + outline CSS + label layer):

```html
<div class="dbgbar"><label><input type="checkbox" id="dbgtoggle"> 🔍 Show part names</label></div>
<style>
.dbgbar { position:fixed; right:16px; top:16px; z-index:9998; }                          /* always reachable (top-right) */
.dbgbar label { display:inline-flex; align-items:center; gap:7px; cursor:pointer; user-select:none;
  padding:8px 12px; border:1px solid #262626; border-radius:999px; background:#111;
  color:#a3a3a3; font:600 12px/1 ui-sans-serif,system-ui; box-shadow:0 8px 24px rgba(0,0,0,.55); }
body.dbg .dbgbar label { border-color:#38bdf8; color:#38bdf8; }                           /* lit when on */
body.dbg [data-dbg]  { outline:1px dashed rgba(56,189,248,.55); outline-offset:-1px; }  /* leaf */
body.dbg [data-dbgc] { outline:1px dashed rgba(168,85,247,.6);  outline-offset:-1px; }  /* container */
.dbg-label { position:absolute; z-index:9999; font-size:8px; font-weight:700; line-height:1.4;
  padding:0 3px; background:#38bdf8; color:#06121a; border-radius:0 0 3px 0; white-space:nowrap; pointer-events:none; }
.dbg-label.c { background:#a855f7; color:#fff; transform:translateX(-100%); border-radius:0 0 0 3px; }  /* container → top-right */
</style>
<script>
(function(){
  const cb = document.getElementById('dbgtoggle');
  function render(){
    document.querySelectorAll('.dbg-label').forEach(e => e.remove());
    if(!document.body.classList.contains('dbg')) return;
    const sx = scrollX, sy = scrollY;
    document.querySelectorAll('[data-dbg],[data-dbgc]').forEach(el => {
      const c = el.hasAttribute('data-dbgc'), name = c ? el.dataset.dbgc : el.dataset.dbg;
      const r = el.getBoundingClientRect(); if(!r.width || !r.height) return;
      const l = document.createElement('div'); l.className = 'dbg-label' + (c ? ' c' : ''); l.textContent = name;
      l.style.top = (sy + r.top) + 'px'; l.style.left = (sx + (c ? r.right : r.left)) + 'px';
      document.body.appendChild(l);
    });
  }
  function set(on){ document.body.classList.toggle('dbg', on); cb.checked = on; render(); }
  cb.addEventListener('change', e => set(e.target.checked));
  if(/[?&]dbg\b/.test(location.search)) set(true);            // ?dbg also enables it (handy for screenshots)
  addEventListener('scroll', render, true); addEventListener('resize', render);
})();
</script>
```

Screenshot the overlay-**on** version alongside the normal one and hand the user both — the labelled shot becomes the shared map for every later "change X" request.

## Ranked critique

For a mock with more than ~2 variants, end the page with a short **ranked critique**: order the variants best→worst with a one-line reason each, and state the recommendation explicitly. This turns a pile of options into an actual recommendation the user can accept or override in one read. (Keep the in-body recommendation and the index card's "recommended" label in sync — drift between them is a common, confusing bug.)

## After creating mocks

- Tell the user the **URL(s)** to open (use a host they can actually reach — if they're on a remote/SSH box, the machine's hostname, not `localhost`) and **which variant you recommend and why**.
- If you can render headlessly, a screenshot is worth more than a description — verify the mock looks right before declaring it done.
- Then **stop.** A mock is a decision artifact; wait for the pick before writing production code.

## What to avoid

- **A mock with no state.** Every index entry carries a badge — an unstated mock is an undead decision.
- **Leaving a shipped design at `open`.** Flip to `implemented` in the same change you ship. Stale badges are the whole failure mode the lifecycle exists to prevent.
- **Lorem ipsum / fake-looking data.** It hides the density and wrapping problems mocks exist to expose.
- **Drift from real components.** Copy the source's actual classes; don't approximate.
- **A single-column responsive mock.** Render true device widths in separate frames.
- **Bundling decisions.** One page, one question.
- **Implementing before a pick.** The point is to get the decision, not pre-empt it.
