# WWW-Keycloak House Rules

Apply to every task in this repository unless explicitly overridden. Bias: caution over
speed on non-trivial work; use judgment on trivial tasks. Loaded automatically at launch
(same priority as `CLAUDE.md`). Subagents get their discipline from skills force-loaded via
`briefing.skills` — this file is for the orchestrating agent.

## Engineering discipline

1. **Think before coding** — state assumptions. When uncertain, ask rather than guess.
2. **Simplicity first** — minimum code that solves the problem; nothing speculative.
3. **Surgical changes** — touch only what you must; match existing style.
4. **Tests verify intent, not just behavior** — reproduce a bug before fixing it; leave a
   regression test behind. A test that can't fail when the logic changes is wrong.
5. **Read before you write** — before new code, read the callers and the sibling module (`WWW::Keycloak::OIDC` ↔ `WWW::Keycloak::Admin`).
6. **Surface conflicts, don't average them** — pick one pattern, explain why, flag the
   other for cleanup.
7. **Checkpoint after every significant step** — done / verified / left.
8. **Fail loud** — "done" is wrong if anything was skipped silently.

## Delegation

This rule depends on whether the Agent/Task tool is available to you.

- **You can spawn subagents** (orchestrating main agent): do NOT touch behavior-relevant
  code yourself — delegate to this repo's worker. Your lane: coordinate, inspect, plan,
  review diffs, run tests, edit non-behavioral docs. When in doubt, delegate.
  Only the `www-keycloak-*` agents get their skills force-loaded via `briefing.skills`; you
  get no briefing and would touch internals with too little context.

  | Task | Agent |
  |---|---|
  | Implement / refactor / debug behavior-relevant code | `www-keycloak-worker` (default) |
  | Write/extend tests | `www-keycloak-test-writer` |
  | Commits, `Changes`, card → done, pre-release audit | `www-keycloak-release-manager` |
  | Write/maintain POD | `www-keycloak-doc-writer` |

- **You cannot spawn subagents** (you ARE a `www-keycloak-*` agent): the delegation lock
  does not apply to you — implement, refactor, debug, and test per these rules.

Behavior-relevant = runtime behavior, the public API (`WWW::Keycloak`, `::OIDC`, `::Admin`), the sync/async sibling invariant, error handling, tests, performance.
Pure prose docs and `Changes` notes are not.

**Only `www-keycloak-release-manager` commits.** A worker leaves a commit-ready tree and hands its card
to `review`; you then dispatch `www-keycloak-release-manager` to cut the commit and close the card.

## Coordination — karr board

Ticket coordination is the orchestrating agent's job, so `karr` is always in scope —
don't invoke the `kanban-issues-karr-coordination` skill first, just use it. Git-native kanban; state lives in
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
A public tracker (GitHub) carries real humans' issues, written under the maintainer's
account. Never act on a public issue on your own initiative — not even to read it. No
listing, viewing, commenting, editing, closing, or creating unless the user explicitly
says to handle a specific issue.

## Project-specific hazards

- **Live tests hit a real Keycloak.** Opt-in via `KEYCLOAK_LIVE_TEST=1 KEYCLOAK_URL=…`, off by
  default. Never run them uncontrolled, and never enable them in a fanned-out/parallel
  context. A default `prove -lr t` must pass with them skipped.
- **Admin calls change a real identity system.** Realm, client and user mutations are not
  test fixtures on a shared instance; live tests create and remove their own throwaway realm.
- **Sync/async twin.** `p5-net-async-keycloak` mirrors this repo's public API with `_f`
  suffixes and Futures. An API change here is incomplete until the twin matches — ticket
  the twin; do not edit the other repo from here.
- **Keycloak facts come from a running instance or its documentation,** never from memory.
  Endpoint paths and claim contents differ between versions.
- **Test runner trap.** Plain `prove -l t/` is non-recursive; always use `prove -lr t` so
  subdir tests are never silently skipped.

## Perl specifics — reference, don't restate

Module loading, Moo patterns, dependency pinning, `[@Author::GETTY]` release metadata,
POD directives, and house style live in skills `getty-perl-core`, `getty-perl-moo`,
`perl-release-dist-ini`, `getty-perl-release-author-getty`, and `www-keycloak-core` (force-loaded
for `www-keycloak-*` agents). Do not duplicate that content here.
