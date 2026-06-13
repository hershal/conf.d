---
name: dump-memory
description: Capture a durable, datestamped knowledge-dump into the project's memory/ folder — the how-and-why of something non-obvious just figured out (a hard bug and its root cause, a subtle design decision, a gotcha-laden fix) so a future agent or human doesn't re-derive it. Use when the user says "write this down", "dump a memory", "save how we did X", or after solving something hard whose lessons the code and git history don't capture on their own. Produces memory/YYYY-MM-DD-<slug>.md. NOT for one-off recall facts (that's auto-memory), a change spec written before the work (that's the plan skill), or a session handoff (that's the handoff skill).
---

# Dump-memory skill

You're writing a durable note to **the future** — the next agent or human who touches this
area months from now — about something non-obvious that was just figured out. The code says
*what* it does; git says *what changed*. This file captures what neither does: **why it's like
this, what was tried and failed, and the traps that will re-bite anyone who doesn't know.**

The single test for whether a memory is worth writing:

> **Would someone competent, reading the code and the git log, still have to re-derive this?**
> If yes — write it. If the code or commit messages already make it obvious — don't.

## Filename and location

```
memory/YYYY-MM-DD-<short-kebab-slug>.md
```

- `YYYY-MM-DD` from `date +%Y-%m-%d` — the day it's written; keep it fixed if edited later.
- Slug: kebab-case, ≤5 words, names the topic (`touch-scroll-restoration`, `auth-token-refresh`).
- Create `memory/` if it doesn't exist. If the project already keeps such notes elsewhere
  (`docs/`, `notes/`), mirror that convention instead of making a second folder.
- Refer to a memory by its **full datestamped filename** in cross-references — the date is part
  of its identity and the chronological sort depends on it.

## What earns a place (and what doesn't)

WRITE a memory for:
- A hard bug whose **root cause was non-obvious** — especially when the obvious fix was wrong,
  or the cause was the opposite of what it looked like. The dead-ends are the gold.
- A **design decision with a non-obvious why** — "we do it this odd way *because* X bites
  otherwise," where the code can't explain itself.
- A **gotcha / sharp edge** in a library, the framework, or this codebase that cost real time
  and will cost it again (race conditions, ordering, platform quirks, env-specific behavior).
- An **investigation conclusion** that took effort to reach and isn't written down anywhere.

DON'T write a memory for:
- A one-off fact for recall ("the API key lives in X") — that's the auto-memory system.
- A change you're about to make — that's the `plan` skill (a spec, written before).
- Where the next session should pick up — that's the `handoff` skill (state-of-the-world).
- Anything the code structure, a comment, or the commit message already makes plain. If asked
  to "remember" something obvious, find what was *non-obvious* about it and capture that instead.

## Structure

Right-size to the topic; drop any section with nothing to say. A small gotcha is a title + TL;DR
+ two bullets. The skim layer (title + TL;DR) must stand alone — a reader decides from it alone
whether this file is the one they need.

```markdown
# <Title> — <one-line of what this captures>

**Date:** YYYY-MM-DD
**Area:** <files / subsystem touched> · **Topic:** bug fix | design decision | gotcha | investigation

> **TL;DR**
> - <2–4 bullets: the upshot — what was figured out and what to do about it, skimmable alone>

## What & why
<How it works now and — the load-bearing part — WHY. The reasoning, constraints, and trade-offs
that aren't visible in the code. Link to code (file:line + grep-able symbol), don't paste it.>

## What bit us / non-obvious gotchas
<The highest-value section. The traps, dead-ends, and counterintuitive findings, ideally in the
order they were hit. Each one: the symptom, the real cause, the fix. This is what saves the next
person hours. If a "fix" made things worse, say so and why — that's often the most useful line.>

## References
<Verified file:line + symbol names. Commit hashes (the trail, if it helps). Related plans/docs/
memories by full filename. External sources or links if a claim rests on them.>

## Verification (optional)
<How it was confirmed — especially anything that can't be tested automatically (a manual
on-device check, a repro that only shows up under load). Lets the next person re-confirm.>
```

## Rules

- **Density, not length.** Every sentence earns its place by changing what a future reader would
  do or believe. Delete anything that just restates the code. (Same discipline as the `plan`
  skill: no padding, no ceremony, plain words.)
- **Ground every reference.** `file:line` and symbol names must be real — verify before writing.
  Prefer `file.ts` + a grep-able symbol over a bare line number, since lines drift.
- **Record the journey only where it teaches.** Unlike a status file, a memory *may* include
  "we tried X, it failed because Y" — but only when the failure is itself the lesson. Don't
  narrate the whole session; distill it to what's durable.
- **Write what's true, including uncertainty.** If the fix is a best-guess that worked but the
  root cause isn't fully proven, say so, and note the next lever to pull if it regresses.
- **One topic per file.** If you're tempted to dump two unrelated things, write two files.

## Procedure

1. `date +%Y-%m-%d` for the stamp; pick a ≤5-word kebab slug for the topic.
2. Confirm `memory/` (or the project's existing notes location); create it if absent.
3. Write `memory/YYYY-MM-DD-<slug>.md` per the structure, applying the "would they re-derive it?"
   test to every section.
4. If the project commits per change, commit the new file with a one-line message naming the
   topic. (No build/restart — it's a doc.)
