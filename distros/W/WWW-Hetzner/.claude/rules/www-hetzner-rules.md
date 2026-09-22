# WWW::Hetzner House Rules

Apply to every task in this repository unless explicitly overridden. Bias: caution over
speed on non-trivial work; use judgment on trivial tasks. Loaded automatically at launch
(same priority as `CLAUDE.md`). Subagents get their discipline from the skills force-loaded
via `briefing.skills` — this file is for the orchestrating agent.

## Engineering discipline

1. **Think before coding** — State assumptions. When uncertain, ask rather than guess.
   Present alternatives when ambiguous. Push back when a simpler approach exists. Stop when
   confused; name what's unclear.
2. **Simplicity first** — Minimum code that solves the problem. Nothing speculative.
3. **Surgical changes** — Touch only what you must. Don't "improve" adjacent code,
   comments, or formatting. Match existing style.
4. **Goal-driven execution** — Define success criteria, loop until verified.
5. **Surface conflicts, don't average them** — Contradicting patterns: pick one (more
   recent / more tested), explain why, flag the other. Don't blend.
6. **Read before you write** — Before new code, read the sibling resource that already
   does the same thing (Servers is the reference), the `Role::IO`/`Role::HTTP` seam, and
   the entity it returns. "Looks orthogonal" is dangerous.
7. **Tests verify intent, not just behavior** — Reproduce a bug before fixing it; leave a
   regression test behind. A test that can't fail when the logic changes is wrong.
8. **Checkpoint after every significant step** — Summarize: done / verified / left.
9. **Match the codebase's conventions, even if you disagree** — Conformance > taste.
10. **Fail loud** — "Done" is wrong if anything was skipped silently. "Tests pass" is
    wrong if any were skipped.

## Delegation

This rule depends on whether the Agent/Task tool is available to you.

- **You can spawn subagents** (orchestrating main agent): Do NOT touch behavior-relevant
  code yourself — delegate to `www-hetzner-worker`. Your lane: coordinate, inspect, plan,
  review diffs, run tests, manage git, edit non-behavioral docs. When in doubt, delegate.
  Why: only the `www-hetzner-*` agents get their skills force-loaded via `briefing.skills`;
  you get no briefing and would touch internals with too little context. Specialist lanes:

  | Task | Agent |
  |---|---|
  | Implement / refactor / debug behavior-relevant code | `www-hetzner-worker` (default) |
  | Write/extend tests | `www-hetzner-test-writer` |
  | Write/maintain POD | `www-hetzner-doc-writer` |
  | Pre-release audit | `www-hetzner-release-checker` |

- **You cannot spawn subagents** (you ARE a `www-hetzner-*` agent): The delegation lock
  does not apply to you — implement, refactor, debug, and test per these rules.

Behavior-relevant = runtime behavior, the public API, the IO transport seam, the
request/response contract, error handling, tests, the CLI surface. Pure prose docs, the
changelog, and README are not.

## Coordination — karr board (always in scope)

Ticket coordination is the orchestrating agent's job, so `karr` is always in scope — don't
invoke the `kanban-issues-karr-cli` skill first, just use it. Git-native kanban; state
lives in `refs/karr/*`; this repo has its own board.

- `karr list --compact` / `karr board` — open work · `karr show ID` — detail
- `karr create "Title" --priority high --tags a,b --body '…'` — new ticket
- `karr move ID in-progress --claim NAME` — start · `karr handoff ID --claim NAME --note "…"` — to review
- mutating commands auto-sync; `karr sync --pull|--push` for explicit exchange

A change to `_build_request`/`_parse_response` shape affects `p5-net-async-hetzner`:
that is a **ticket on that repo's board**, never a silent cross-repo edit. Full command
surface: skill `kanban-issues-karr-cli`.

**Serialize board mutations when fanning out.** Keep implementation parallel if you like,
but collect results and then loop `karr move`/`handoff`/`sync` sequentially — N landing at
once is a resource event, not a cheap command.

## Release — never without permission

`dzil build` / `dzil test` / `prove -lr t/` are fine anytime. `dzil release` and any
upload/tag/push are STRICTLY forbidden without the maintainer's explicit go-ahead — even
if a plan or STATUS document lists "release" as the next step. The local working-tree
version is authoritative; a lagging CPAN version is never a blocker and never a ticket.
For anything heading toward release: stop and ask.

## Project-specific hazards

- **The IO seam is load-bearing and shared.** `Role::IO`'s `call($req)` is the single
  chokepoint every request passes through; both `Net::Async::Hetzner` and the test mock
  plug into it. Code that reaches past it to LWP directly passes its own tests and
  silently breaks the async client and the mock harness at once — the wrong thing looks
  right. Always go through `_build_request` → `io->call` → `_parse_response`.
- **Tests must never hit the network.** The mock harness (`Test::WWW::Hetzner::MockIO` in
  `t/lib/`) exists so no test needs a real token. A "quick live check" against a real
  Hetzner account can create or destroy real infrastructure — extend a fixture instead.

## Perl / Moo / release specifics — reference, don't restate

Moo class and role patterns, the distribution architecture and test harness, the
`[@Author::GETTY]` POD and release conventions, and `dist.ini` details live in skills
`getty-perl-moo`, `www-hetzner-core`, `getty-perl-release-author-getty` and
`perl-release-dist-ini` (force-loaded for `www-hetzner-*` agents). Do not duplicate that
content here.
