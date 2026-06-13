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

## Responsive mocks: render at true device widths

If a component re-lays-out across breakpoints, **do not** show it in a single narrow column — that clips wider layouts to the mock's own width and hides exactly what you're trying to judge. Instead:

- Render each breakpoint in its **own fixed-width frame** at the **true device width** (e.g. ~390px mobile, ~834px tablet, ~1280px desktop), each in its own horizontally-scrollable box.
- Prefer **one container-query template per variant** that re-flows by its container's width, then drop that single template into each device frame — so the mock proves the *same* markup adapts, rather than hand-faking three layouts.
- Label each frame with its width.

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
