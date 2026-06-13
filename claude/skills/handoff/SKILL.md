---
name: handoff
description: Create a new handoff document for the next agent (or human) picking up the project. Use this at the end of a substantial session when you've completed work that someone else needs to continue. Writes a timestamped file at `docs/handoffs/YYYY-MM-DD-HHMM-<description>.md`, indexes it in `docs/handoffs/README.md`, and points the latest-handoff reference at it. The description is the short kebab-case slug after the timestamp (e.g. "stage4-cot-generation").
---

# Handoff skill

You're creating a numbered, timestamped handoff document that the next session can pick up cold. Treat the reader as a smart colleague who just walked into the room — they've never seen this conversation, don't know what you've tried, don't know what's blocked.

## Filename

Use the **current local date and 24-hour time** at the moment you write the handoff:

```
docs/handoffs/YYYY-MM-DD-HHMM-<short-kebab-description>.md
```

- `YYYY-MM-DD` and `HHMM` taken from `date +"%Y-%m-%d-%H%M"`.
- Kebab-case description, ≤6 words, says what the **receiving** agent picks up — not what you just did. E.g., `stage4-cot-generation`, `cluster-training-resume`, `dataset-review-corrections`.

Get the timestamp with a single Bash call:

```bash
date +"%Y-%m-%d-%H%M"
```

If the repo has no `docs/handoffs/` directory yet, create it. If the project keeps docs elsewhere, mirror the existing convention instead.

## What goes in the file

Structure:

```markdown
# <title that matches the filename description>

<one paragraph: what state the project is in right now and what the next agent should do first>

## What's done

<a tight list of completed work in this session. Bullet points, with row counts /
artifact paths / commit hashes where applicable. Don't narrate the journey — say
what's true now.>

## What's NOT done (priority order)

### A. <first task the next agent picks up>

<concrete description: what to do, where the relevant code/data is, what the
inputs are, what the output should look like. If there's a designed-but-not-built
component, point at where the design lives.>

### B. <next task>
...

## Critical paths and operational details

<commands to re-run common stages, paths to artifacts, gotchas the next agent
will hit. Be specific. "Run X" not "you can run X if you want." If something
is idempotent, say so. If something costs money, say how much.>

## Open / unresolved items

<bulleted list of decisions the user deferred, ambiguities, things you noticed
but didn't fix. The next agent shouldn't have to rediscover these.>

## File map quick reference

<a small tree of the files most relevant to the handoff. Not the whole repo —
just what the next agent will touch.>

## Notes for the next agent

<anything else that doesn't fit the above. Style preferences, things to NOT
re-litigate, prior decisions that are load-bearing.>
```

## After writing the file

1. **Add a row to `docs/handoffs/README.md`** in the index table (timestamp, file link, one-line topic, **Status**). New handoffs start at `open`. Newest at the bottom. Create the README with the header — including a Status column — if it doesn't exist.
2. **Supersede the prior handoff** if this one carries its unfinished work forward: set that row's Status to `superseded` in the index, and prepend a one-line banner to the top of its file: `> **Status: superseded** by [<new-file>](<new-file>.md) — YYYY-MM-DD`. The lexically-latest `open` handoff is always the live baton. (If the prior work was actually *finished* rather than passed on, the closeout skill marks it `done` instead — see Status lifecycle.)
3. **Update the project's "latest handoff" pointer** if the repo has one (e.g. a `docs/repo_map.md`, top-level README, or CLAUDE.md line that tracks the current handoff) — point it at the new file as "Latest".
4. **Reference the prior handoff inline** if it's still load-bearing (so the next agent reads it for context). Use a relative path like `[prior-handoff.md](prior-handoff.md)`.
5. **Commit** the new handoff + index updates as one commit (only if the repo is a git repo and the user expects commits). Message like: `Handoff: <description>`.

## What to avoid

- Don't make the handoff a session journal. The next agent doesn't care what you tried — only what's true now and what to do next.
- Don't restate things that already live in the project's design docs or runbooks. Link to them instead.
- Don't write a handoff for trivial work. Use this for substantial transitions (stage completed, design approved, fanout done, etc.).
- Don't pick a description that describes the past tense ("stage3-completed"). Describe what the receiver is picking up ("stage4-cot-generation").

## Status lifecycle

A handoff is a baton, so it has a lifecycle — tracked in the index table's **Status** column, which is both the source of truth and the dashboard a new session scans first to find the live baton:

- **`open`** — written, awaiting pickup; the lexically-latest `open` handoff is the current one.
- **`done`** — its work was completed. Set by the **closeout skill** when the session that finished the work wraps up.
- **`superseded`** — replaced by a newer handoff before its work was done (the baton was passed onward, not dropped). Set by this skill when you write the successor (step 2 above).

There is deliberately **no `in-progress` state.** A session has no reliable moment to flip `open → in-progress` when it picks the baton up — it just reads the latest handoff and starts — so that marker would silently rot. Instead, transitions happen only at moments a skill reliably acts: writing a successor (here), and closeout (which checks whether the session came from a handoff and marks the source `done` or `superseded`). **A status nobody updates is worse than none — only set status where a skill drives it.**

When you close or supersede a handoff, also prepend the one-line banner to its file so someone who opens it directly isn't misled by stale content. It's a terminal stamp, written once, so it can't drift.

## Prior handoffs index

See `docs/handoffs/README.md` for the full table of past handoffs. **The lexically-latest `open` file is the current handoff.**
