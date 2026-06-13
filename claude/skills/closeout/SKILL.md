---
name: closeout
description: Cleanly wrap up a working session — surface the remaining open threads from the discussion, then leave a paper trail so a future agent or human can pick the work up cold. Triages five vectors (docs to update, a plan-status to refresh, project knowledge to dump, user/process memories to save, and a handoff to write) and delegates to the handoff, plan, and dump-memory skills as needed. Use when the user runs /closeout, is running low on context window, or wants to wind down and end the session.
---

# Closeout skill

The session is ending — the user is out of context window, switching tasks, or just done for now. Your job is to **close it cleanly**: name what's still open, then make sure every loose thread is either resolved or written down somewhere durable, so a fresh agent (or the user, days later) can resume without re-reading this conversation. You have the full session in context right now and they won't. Spend that context before it's gone.

This skill is a **router**, not a new format. It identifies what paper trail is needed and delegates to the specialized skills (`handoff`, `plan`, `dump-memory`) and the auto-memory store. Don't reinvent their structures — invoke them.

## The goal (one line)

> Leave the project in a state where the single question *"what happens next, and what do I need to know to do it?"* is answered in writing — not in this chat log that's about to disappear.

## When to use

- The user runs `/closeout`, says they're wrapping up, running low on context, or want to continue later.
- The end of any substantial session, as a discipline — even if the answer turns out to be "nothing to write down."

Skip the heavy machinery for a trivial session (a one-line fix, a quick question answered). Say so plainly and stop — don't manufacture a handoff or a memory just to have produced one. Each sub-skill has its own "don't do this for trivial work" guard; honor it.

## Procedure

### 1. Surface the opens (do this first, before asking anything)

Reconstruct the session's loose ends from context — don't ask the user cold, *show them a list*. Sweep for:

- **Unfinished work** — things started but not done, code written but not tested, a step left mid-stream.
- **Deferred decisions / open questions** — anything the user said "later" to, ambiguities you flagged, choices not yet made.
- **Uncommitted state** — run `git status`. A dirty tree at session end is itself an open thread (this user commits per change). Flag untracked/modified files and unpushed commits.
- **Promised-but-not-done** — anything you said you'd do and didn't.
- **Known limitations** — things you shipped with a caveat.

Present these as a tight bulleted list and ask the user: *"Here's what I see still open — anything to add, or anything here that's actually settled?"* Let them correct the list before you act on it.

### 2. Decide whether a handoff is needed — infer first, ask only if genuinely unclear

Whether work continues in a new session gates the handoff (vector 5). **Infer this from the session; don't reflexively ask.** Your main evidence is the size of the opens you just surfaced in step 1, crossed with whether the user has signalled context pressure:

- **Substantial opens + a context/ending signal** → treat as *continuing*. A handoff is warranted — **propose** it as part of the plan, don't ask whether to write one. The canonical signal is **the user mentioning context — that it's getting full, running low, or running out** (this is often *why* they're closing out); also counts: "wrapping up", "continue this later", or invoking `/closeout` with real work still in flight.
- **Opens are trivial, or the work is finished and committed** → treat as *done*. Skip the handoff.
- **Genuinely ambiguous** — real opens but no signal either way → *then* ask, once, with `AskUserQuestion`: "Continuing later" vs "Done". One question, not a quiz.

Don't make the user state what you can already read off the session. The same discipline as "don't ask blind" in step 1 applies here: read the evidence first, ask only for what you truly can't infer.

### 3. Check the five vectors — this is *your* checklist, not a report

Walk each vector below and ask yourself its question against the actual session. Most sessions trigger one or two, not all five. Decide which apply and what each one's action is.

This framework is internal scaffolding for *your* reasoning. **Do not narrate it to the user** — never show them the word "triage", a "vector N" list, an "N/A" table, or the checklist verbatim. When you report (step 6), translate the outcome into plain sentences: what genuinely needs writing down, and what you did about it.

### 4. Confirm the close-out plan

Before writing anything, lay out the proposed actions as a short checklist — *"To close out I'll: update X doc, refresh the Y plan-status, dump a memory on Z, and write a handoff. Skip any of these?"* — and get a go-ahead. The user may trim it (e.g. "skip the handoff, just save the preference"). Don't spawn four artifacts unannounced.

### 5. Execute in dependency order

Write in this order so later artifacts can reference earlier ones, and **the handoff comes last as the capstone that points at everything else**:

> docs → plan-status → project memory → auto-memory → **handoff**

Invoke each sub-skill via the Skill tool (`handoff`, `plan`, `dump-memory`) rather than hand-rolling its file. Ensure each artifact gets committed per the project's commit-per-change convention (the sub-skills handle their own commits where they do; sweep up any stragglers).

### 6. Final summary

Close with a short, **plain-language** recap (a few lines, no jargon, no checklist): what you wrote and where (with paths), and the **one** thing the next session should do first. That recap is the last thing the user sees before the session dies — make it the pointer they'd want.

## The five vectors

### 1. Documentation — *did anything we changed make a doc wrong or incomplete?*

**Signal:** a new command/flag/env var, a changed workflow, a renamed thing, a "we now do X instead of Y", a behavior a runbook describes. CLAUDE.md, READMEs, runbooks, design docs, config docs.
**Action:** edit the doc in place — no new skill, just fix it, tightly. Don't let docs silently drift from what the session changed.

### 2. Plan status — *is there an active plan whose as-built ledger is now stale?*

**Signal:** you implemented steps from a `plans/*.plan.md` this session, but its paired `.plan-status.md` doesn't reflect what landed (or doesn't exist), or the plan's `status:` is behind reality.
**Action:** invoke the **`plan`** skill to update the `.plan-status.md` (Done mapped to step IDs, Deltas from the plan, Follow-ups) and flip the plan's `status:`. A stale status file misleads the next reviewer.

### 3. Project knowledge — *did we figure out something non-obvious the code and git won't tell the next person?*

**Signal:** a hard bug whose root cause was counterintuitive, a design decision with a non-obvious why, a gotcha that cost real time. Apply the test: *would someone competent, reading the code and git log, still have to re-derive this?*
**Action:** invoke the **`dump-memory`** skill → `memory/YYYY-MM-DD-<slug>.md`. This is durable *project* knowledge.

### 4. User & process memory — *did the user explicitly ask to remember something, or has a called-out issue recurred?*

**Be conservative — the default is NOT to save.** A memory store earns its value by staying small; most things that surface in a session do not belong in it. Save a memory **only** when one of these clears the bar:

- **The user explicitly says to remember it** — "remember this", "save that", "from now on…", or an emphatic standing instruction ("NEVER do X"). Their words are the trigger, not your judgment that a fact seems useful.
- **A recurring, called-out issue** — the same mistake or friction has come up **more than twice**, *especially* one the **user has explicitly called out**. Wait for the pattern; a single correction is not enough.

A passing "I prefer X", or a lesson *you* learned once this session, does **not** clear the bar — leave it. When in doubt, don't save: an over-eager store is noise that buries the few facts that matter, and the user has flagged exactly this over-eagerness.

**Action (only if the bar is cleared):** write to the **auto-memory store** (the `memory/` + `MEMORY.md` system described in your system prompt — one fact per file with frontmatter, plus a one-line `MEMORY.md` pointer; check for an existing file to update before creating a duplicate). This is distinct from vector 3: vector 3 is *project knowledge*; this is *about the user and how to work*, and persists across all sessions on this project.

> **3 vs 4, quickly:** "We cache the lookup because the ORM re-queries 3× otherwise" → project memory (vector 3). "Hershal wants every change committed separately" → auto-memory (vector 4) — but only once it's an explicit instruction or a repeated, called-out pattern, not a one-off remark.

### 5. Handoff — *will work continue, and would a cold reader need orientation?* (capstone if continuing; **also fires to close a source handoff** if this session came from one)

**First, did this session come from a handoff?** Check whether you started from or worked against an existing `docs/handoffs/*.md` (it was the live `open` baton). If so, its status must be updated now — this is the transition the whole handoff lifecycle depends on, and the one moment an agent reliably acts on it:

- **Work finished (step 2 = done)** → mark that source handoff `done`: flip its row in `docs/handoffs/README.md` and prepend a `> **Status: done** — YYYY-MM-DD` banner to its top.
- **Continuing (step 2 = continuing)** → the successor you write below supersedes it; the `handoff` skill flips the source to `superseded` as part of writing the new one.

Do this **automatically and report it in the recap** — don't ask first. Leaving a finished session's source handoff sitting at `open` is the exact stale-baton problem the status field exists to prevent.

**Signal (write a new one):** the user is continuing later (especially if out of context) and there's enough live state that a fresh agent shouldn't have to reconstruct it. Skip for a finished or trivial slice.
**Action (if continuing):** invoke the **`handoff`** skill → `docs/handoffs/YYYY-MM-DD-HHMM-<slug>.md`, indexed and pointed-to per that skill. The new handoff starts at `open`. Write it **last** so it can reference the docs, plan-status, and memories you just produced — it's the map to the whole paper trail.

## What to avoid

- **Asking blind.** Don't open with "any open items?" — reconstruct them from the session and present a list to react to. You have the context; use it.
- **Manufacturing artifacts.** A quiet session may need nothing. Saying "nothing to close out, the tree is clean and the work is done" *is* a valid closeout.
- **Over-saving memories.** Saving a memory is the rare exception, not a closeout checklist item. Don't persist every preference or lesson — save only on an explicit "remember this" or a pattern that's recurred 2+ times (see vector 4). Most closeouts save zero memories.
- **Duplicating the sub-skills.** Don't hand-write a handoff or memory file — invoke the skill so format and indexing stay consistent.
- **Skipping the git check.** Uncommitted changes are the most common silently-dropped open thread. Always run `git status`.
- **Burying the next step.** The final recap exists so the next session starts in one read. Lead with what to do first.
- **Narrating the scaffolding.** The five-vector checklist is how you *think*, not how you *report*. Dumping "triage / vector 1: N/A / vector 2: …" on the user reads as ceremony and buries the point. Say it plainly: "Everything's committed; I saved the one preference worth keeping; no handoff needed." If nothing fired, one sentence is the whole report.
