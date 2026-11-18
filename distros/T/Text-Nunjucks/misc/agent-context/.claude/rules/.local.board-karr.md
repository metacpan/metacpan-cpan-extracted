---
description: Coordinating work on a karr board — always in scope for the orchestrating agent, always pushed, serialized board writes, cross-repo handoff.
---

# Coordination — karr board

Ticket coordination is the orchestrating agent's job, so `karr` is always in scope — use it
directly; skill `kanban-issues-karr-coordination` holds the full command surface. Git-native
kanban; state lives in `refs/karr/*`, one board per repo.

**The board is how agents exchange work — keep it pushed.** Other agents, sessions and
machines see a card only once it is on the remote, so every board write pulls first and
pushes `refs/karr/*` after. That push is durably authorized and outside the publish gate:
never ask before a board write, never save findings up for later, never pass `--local-only`
to avoid the push — it is for a remote that cannot be reached. A "don't push" in a plan or
brief means commits and tags, not the board. A push that fails (credentials, rejected) goes
at the top of your report, and `karr sync` catches up once it works again. Card text is as
public as the repository: no secrets, no home-directory paths.

- `karr list --compact` / `karr board` — open work · `karr show ID` — detail
- `karr create "Title" --priority high --tags a,b --body '…'` — new ticket
- `karr edit ID -a "note"` · `--claim NAME` · `--block "why"` — update
- `karr move ID in-progress --claim NAME` — start · `karr handoff ID --claim NAME --note "…"` — to review
- `karr sync` — pull, then push, by hand: after a failed push or `--local-only`

**Write ticket ids as `kNN`** (`k12`) in commits, notes and docs — never `#12`, which every
hosting platform links to its own issue 12.

**Serialize board writes when fanning out.** Implementation may run in parallel; collect the
results, then loop `move`/`handoff`/`sync` one after another — N of them landing at once has
OOM-rebooted a host.

**Check once, act.** No background poll loops on the board.

**Drift found mid-change becomes a ticket**, not scope creep.

**Cross-repo work is a ticket on the other repo's board** — never a silent edit there,
unless the project rules allow direct edits.
