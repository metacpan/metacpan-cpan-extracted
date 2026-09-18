# WWW-OpenBao House Rules

Apply to every task in this repository unless explicitly overridden. Bias: caution over
speed on non-trivial work; use judgment on trivial tasks. Loaded automatically at launch
(same priority as `CLAUDE.md`). Subagents get their discipline from skills force-loaded via
`briefing.skills` — this file is for the orchestrating agent.

## Engineering discipline

1. **Think before coding** — state assumptions. When uncertain, ask rather than guess.
2. **Simplicity first** — minimum code that solves the problem; nothing speculative. This
   distribution's selling point is that it is small.
3. **Surgical changes** — touch only what you must; match existing style.
4. **Tests verify intent, not just behavior** — reproduce a bug before fixing it; leave a
   regression test behind. A test that can't fail when the logic changes is wrong.
5. **Read before you write** — one file holds the whole client; read `_request` and its
   callers before adding a method beside them.
6. **Surface conflicts, don't average them** — pick one pattern, explain why, flag the
   other for cleanup.
7. **Checkpoint after every significant step** — done / verified / left.
8. **Fail loud** — "done" is wrong if anything was skipped silently.

## Delegation

This rule depends on whether the Agent/Task tool is available to you.

- **You can spawn subagents** (orchestrating main agent): do NOT touch behavior-relevant
  code yourself — delegate. Your lane: coordinate, inspect, plan, review diffs, run tests,
  manage git, edit non-behavioral docs. When in doubt, delegate. Only the `www-openbao-*`
  agents get their skills force-loaded via `briefing.skills`; you get no briefing and would
  touch internals with too little context.

  | Task | Agent |
  |---|---|
  | Implement / refactor / debug behavior-relevant code | `www-openbao-worker` (default) |
  | Write/extend tests | `www-openbao-test-writer` |
  | Pre-release audit | `www-openbao-release-checker` |
  | Write/maintain POD and README | `www-openbao-doc-writer` |

- **You cannot spawn subagents** (you ARE a `www-openbao-*` agent): the delegation lock
  does not apply to you — implement, refactor, debug and test per these rules.

Behavior-relevant = runtime behaviour, the public API (`WWW::OpenBao` attributes and
methods), the `_request` seam, the croak/undef error contract, the dependency set, tests.
Prose in `README.md` and `Changes` notes are not.

## Coordination — karr board

Ticket coordination is the orchestrating agent's job, so `karr` is always in scope —
don't invoke the `kanban-issues-karr-cli` skill first, just use it. Git-native kanban; state lives in
`refs/karr/*`; this repo has its own board.

- `karr list --compact` / `karr board` — open work · `karr show ID` — detail
- `karr create "Title" --priority high --tags a,b --body '…'` — new ticket
- `karr move ID in-progress --claim NAME` — start · `karr handoff ID --claim NAME --note "…"` — to review
- mutating commands auto-sync; `karr sync --pull|--push` for explicit exchange

**Serialize board mutations when fanning out.** Keep implementation work parallel, but
collect results and then loop `karr move`/`handoff`/`sync` sequentially — concurrent board
writes are a resource event, not a cheap command (this shared box has OOM-rebooted on it).
No background poll loops on the board: check once, act on the result.

## Release — never without permission

`prove -lr t` and `dzil build`/`dzil test` are fine anytime. `dzil release` and any CPAN
upload are STRICTLY forbidden without the maintainer's explicit go-ahead — even if a plan
or STATUS document lists "release" as the next step. For anything heading toward release:
stop and ask.

## Public issues — never act without instruction

Two trackers, two universes. **karr** is the internal agent work board, churned freely.
**GitHub** (`Getty/p5-www-openbao`) carries real humans' issues, written under the
maintainer's account. Never act on a GitHub issue on your own initiative — not even to
read it. No listing, viewing, commenting, editing, closing or creating unless the user
explicitly says to handle a specific issue.

## Project-specific hazards

- **A second copy of this module lives in `hi-proto`.** `~/dev/perl/hi-proto/lib/WWW/OpenBao.pm`
  is the pre-extraction original: byte-identical code today, minus `$VERSION` and the POD,
  and hi-proto does **not** depend on this distribution in its cpanfile. So a fix here
  silently does not reach hi-proto, and the two only look in sync because nobody has
  changed either yet. Any behaviour change here needs a karr ticket against `hi-proto`;
  never edit that repo from this one.
- **Other consumers.** `goldmine` (`Goldmine::OpenBao`, `Goldmine::Task::Role`,
  `Goldmine::CLI::Command::Openbao`) and `hiplatform` (`HIP::OpenBao`) wrap this client. A
  change to the croak/undef contract or to what `delete_secret` deletes lands in their
  error handling, not in ours — ticket them.
- **The suite is offline by construction and must stay that way.** No live OpenBao, no
  k8s, not even localhost. `_http` is lazy precisely so it can be stubbed. A test that
  needs a running server is a release blocker, not a coverage win.
- **`delete_secret` is the irreversible one.** It hits `metadata/`, removing the key and
  every version. Anything that touches it — code, POD, or a test's expectations — is
  handling a data-loss path; treat it accordingly.
- **Test runner trap.** Plain `prove -l t/` is non-recursive; always `prove -lr t` so
  subdir tests are never silently skipped (the suite is flat today, keep `-r` anyway).

## Perl and API specifics — reference, don't restate

Module loading, Moo patterns, dependency pinning, `[@Author::GETTY]` release metadata and
POD directives live in skills `getty-perl-core`, `getty-perl-moo`, `perl-release-dist-ini` and
`getty-perl-release-author-getty`. Repo conventions are in `www-openbao-core`; the OpenBao/Vault
HTTP API itself is in `openbao-general`. All force-loaded for `www-openbao-*` agents. Do
not duplicate that content here.
