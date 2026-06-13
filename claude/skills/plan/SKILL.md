---
name: plan
description: Author or update a project plan as a paired .plan.md (the spec agents review before implementing) and .plan-status.md (the as-built ledger). Use when the user wants to write a plan/design file, capture a change for agent review before implementation, structure a refactor, or record what shipped. Produces files under plans/ named YYYY-MM-DD-<slug>.plan.md. Plans are an agent-to-agent medium that a human must still be able to skim in under a minute.
---

# Plan skill

You're writing a plan that **agents** pass between each other — one agent drafts it, other agents review it, another agent implements it — but that a **human** must be able to skim in under a minute to approve or redirect. Write for both readers at once. The structure below makes that possible: a human reads the frontmatter + the TL;DR box + the section headers and stops; an agent reads the whole thing.

Two files, paired by name:

- **`<slug>.plan.md`** — the spec. Written *before* the work. The thing reviewers critique and the implementer executes.
- **`<slug>.plan-status.md`** — the as-built ledger. Written *during/after* implementation. What actually landed and where it diverged.

## Filenames and location

```
plans/YYYY-MM-DD-<short-kebab-slug>.plan.md
plans/YYYY-MM-DD-<short-kebab-slug>.plan-status.md
```

- `YYYY-MM-DD` from `date +%Y-%m-%d` (the day the plan is created; keep it fixed even as the plan is edited later).
- Slug: kebab-case, ≤5 words, names the change (`brokerage-ready`, `rvol-fix`, `per-play-exits`).
- If the project keeps plans somewhere other than `plans/`, mirror the existing convention. Create `plans/` if it doesn't exist.
- The two files share the exact same stem so they sort adjacently.
- **Always refer to a plan by its full datestamped filename** — in prose, in chat, in `related:` links, in the status header, and in any cross-reference. Never abbreviate to the bare slug or drop the date (`brokerage-ready.plan.md` ✗ → `2026-06-08-brokerage-ready.plan.md` ✓). The datestamp is part of the plan's identity; the chronological sort and the ability to find a plan depend on it never being dropped.

## The two-reader principle (this is the point)

A plan fails if a human has to read all of it to know what it does. Enforce two layers:

1. **Skim layer** — frontmatter + the `> TL;DR` box + section headers. Must convey *what changes, why, how risky, and what decision is being asked* without reading a single body paragraph. A human lives here.
2. **Detail layer** — the body sections. Precise enough that an implementing agent needs nothing else, and a reviewing agent can cite exact steps. Agents live here.

If the skim layer can't stand alone, the plan isn't done.

## `.plan.md` structure

```markdown
---
name: <Title Case name>
created: YYYY-MM-DD
status: draft            # draft → reviewed → in-progress → shipped | superseded
author: <agent/model id or human>
references:              # real, VERIFIED anchors — file:line and what's there
  - path/to/file.py:120 (what lives here / why it matters)
related:
  - plans/<other>.plan.md (one-line why it's linked)
---

> **TL;DR**
> - **What:** <one sentence — the change being made>
> - **Why:** <one sentence — the problem it solves>
> - **Blast radius:** <files/systems touched> · risk: <low | medium | high>
> - **Decision needed:** <the one thing a reviewer/human must approve — or "none, proceed">

<!-- MAP — include ONLY for large multi-part plans; omit for small ones.
## Map
- **P1 — <phase>:** <what it delivers>
- **P2 — <phase>:** <what it delivers>
Lets a human read TL;DR + map in a minute, then drill into one part. -->

## Problem
<What's wrong now, grounded in verified file:line. State the problem only — no solution yet.>

## Goal
<The target end-state in 1–3 sentences. What "done" looks like and how you'd know.>

## Design
<The approach. Subsection by area (Backend / Frontend) or by Part A / Part B.
LINK to code, don't paste large blocks. Each part states its essential decision and why,
not every line of the diff.>

## Steps
1. **S1 —** <action> — `file.py`: <what changes>
2. **S2 —** <action> — `other.py`: <what changes>
<Stable IDs (S1, S2…) so a reviewer can say "S3 is wrong" and the implementer can map
status back. Each step independently implementable and checkable.>

## Test plan
<What proves it works: unit cases, integration, the manual check. Name the repo's test
command. New endpoint/model/behavior → name the test that must exist.>

## Risks & open questions
- **Q1 —** <a decision a reviewer should answer, by ID>
- <a risk to watch; mark any unverified assumption as `ASSUMPTION (unverified): …`>

## Appendix (optional — skippable)
<Exhaustive research, alternatives considered, derivations, backtest detail, long rationale.
Everything that would bloat the skim goes here. A human never needs it; an agent may.
If this grows large, split it into a separate `<slug>-research.md` and link it.>
```

## `.plan-status.md` structure

```markdown
# <name> — status

**Plan:** [<slug>.plan.md](<slug>.plan.md) · **Updated:** YYYY-MM-DD · **Status:** in-progress | shipped
**Branch / commits:** <branch> (<short hashes>)

## Done
<What actually landed. Map to step IDs (S1, S2…) where possible, with file:line and commit
hashes. State what is TRUE now — not the journey, not what you tried.>

## Deferred
<In the plan but deliberately not in this slice, each with a one-line why.>

## Checks
<Concrete results: `pytest …` → N passed; typecheck/lint status. Not "tests pass" — the numbers.>

## Deltas from the plan
<Where the as-built diverged from the spec, and why. This is the highest-value section for a
reviewer — it's where the plan was wrong or reality intervened. Don't omit it.>

## Follow-ups / spun off
<New plans created, known limitations, TODOs left for later.>
```

## Grounding rules (non-negotiable)

- Every `file:line` in `references` and in steps must be **real and verified** — open the file and confirm before writing it down. A plan full of confident-but-wrong line numbers wastes every downstream agent's time.
- Line numbers drift: prefer `file.py` + a grep-able symbol name over a bare line number when the anchor is a function, not a specific line.
- Mark anything you didn't verify as `ASSUMPTION (unverified): …` so reviewers know exactly what to check. Never present a guess as a fact.
- If a claim is external (an industry practice, a library behavior, a perf number), cite a source or label it as your judgment. Don't fabricate authority.

## Density, not length (right-size to the change)

The target is **information density, not a word count**. A plan should be exactly as long as the change requires — no shorter, no longer. There is **no size cap**: rebuilding an app from scratch with layered requirements is legitimately a long plan; padding a one-function fix to look substantial is bloat. Judge by a single test:

> **Density test:** every sentence earns its place by changing what a reviewer or implementer would do. If a sentence can be deleted without losing a decision, a constraint, a file reference, or a risk — delete it.

Apply that test at both ends:

- **Don't bloat the simple.** Match the plan's size and register to the change. A ~10-line change is a few plain sentences — frontmatter, a TL;DR, maybe two or three Steps — not a multi-section document. Drop every section that has nothing to say (an empty "Risks" or a "Goal" that just restates the TL;DR is noise). If a change is so small it's faster to just make it, skip the plan entirely (see "When NOT to use this").
- **Plain words over jargon.** Write the way you'd explain the change to a competent colleague out loud. Don't dress a small fix in architecture vocabulary, ceremony, or invented terms-of-art — say what changes and why in ordinary language. Reserve precise technical terms for where they're load-bearing (a real API name, an actual pattern in the code), not as decoration. If a plainer word works, use it.
  - *Right-size example — a small plan, in full:* TL;DR ("What: cache the user lookup in `get_profile`. Why: it's queried 3× per request. Blast radius: `profile.py` · risk: low. Decision needed: none, proceed.") → Problem (two sentences) → Steps S1–S2. That's the whole plan. No Design section, no Appendix, no jargon.
- **Don't truncate the genuinely large.** When the change is one coherent large thing (a rewrite, a multi-subsystem migration), let the plan be large. The fix for a large plan is **navigability, not deletion** — see below. Cutting necessary requirements to hit a length target is worse than a long plan.

**Keeping a large plan skimmable.** Length is fine; an *unnavigable wall* is not. For a big plan:

- Open with the TL;DR box (still stands alone) plus a short **map** — a bulleted list of the phases/parts and what each delivers. A human reads TL;DR + map in a minute, then drills only into the part they own.
- Give every phase/requirement a **stable ID** (`P1`, `R3`, `S2`) so reviewers and implementers address pieces precisely and the status file maps back to them.
- Make each phase/part **independently readable** — a reviewer assigned Part C shouldn't have to read Parts A–B first.
- Push depth that not everyone needs (research, alternatives, derivations, full backtests) into `## Appendix` or a separate `-research.md`. This isn't a length cap — it's keeping the decision path clear of reference material.

**Always:**

- **One coherent change per plan.** "Coherent" can be large. But if it's three *loosely-related* things bolted together, write three linked plans and cross-link via `related:`. The test is coherence, not size.
- **Link, don't paste.** Reference `file.py:120`; quote at most a few lines when the exact text is load-bearing. Never paste whole functions.
- Keep the frontmatter `status` and the TL;DR box current — they're read the most. A stale `status:` is worse than none.

## Review workflow this structure supports

1. **Draft** — one agent writes `<slug>.plan.md` at `status: draft`.
2. **Review** — other agents critique by ID ("S3 misses the staleness guard", "Q1: yes, gate on regime"). Because steps and questions have stable IDs, review is surgical, not a re-read. Update the plan and flip to `status: reviewed`.
3. **Implement** — an agent executes the steps, then writes `<slug>.plan-status.md`, mapping Done back to step IDs and recording Deltas. Flip the plan to `in-progress` then `shipped`.
4. **Supersede** — if a plan is replaced, set `status: superseded` and link the replacement in `related:`. Don't delete it.

## When NOT to use this

- A one-line fix or a change you're making right now — just make it.
- A handoff between sessions — use the `handoff` skill instead (different shape: state-of-the-world for the next agent, not a change spec).
- Pure research with no change attached — write a doc, not a plan.

## What to avoid

- A plan whose TL;DR can't stand alone — the human-skim layer is the whole point.
- Pasting walls of code; the plan references code, it doesn't mirror it.
- A status file written as a session journal ("first I tried X, then Y"). It records what's true now and what diverged.
- Unverified `file:line` anchors presented as fact.
- Letting the Appendix's bulk leak up into the body. Keep the skim path lean.
