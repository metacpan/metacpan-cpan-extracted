# WWW::Hetzner House Rules

Apply to every task in this repository unless explicitly overridden. Bias: caution over speed on
non-trivial work, judgment on trivial tasks. Loaded at launch (same priority as `CLAUDE.md`).
Subagents get their discipline from the skills force-loaded via `briefing.skills`.

## Engineering discipline

1. **Think before coding** — State assumptions, ask rather than guess, present alternatives
   when ambiguous, push back if a simpler approach exists, stop when confused and name what
   is unclear. Define success criteria, loop until verified.
2. **Simplicity first** — Minimum code that solves the problem. Nothing speculative, no
   abstraction for single-use code.
3. **Surgical changes** — Touch only what you must; don't "improve" adjacent code, comments
   or formatting.
4. **Read before you write** — Before new code, read the neighbouring controller, the entity it
   returns and the transport seam you are about to use. "Looks orthogonal" is dangerous.
5. **Tests verify intent** — Reproduce a bug before fixing it; leave a regression test behind.
   A test that can't fail when the logic changes is wrong.
6. **Fail loud** — "Done" is wrong if anything was skipped silently; "Tests pass" is wrong if
   any were skipped. Checkpoint after every significant step: done / verified / left.
7. **Conformance over taste** — Match the codebase's conventions, even if you disagree;
   surface a harmful convention, don't fork silently. Conflicting patterns: pick one (more
   recent / more tested), explain why, flag the other. Don't blend.

## Delegation

This rule depends on whether the Agent/Task tool is available to you.

- **You can spawn subagents** (orchestrating main agent): Do NOT touch behavior-relevant code
  yourself — delegate to `www-hetzner-worker`. Your lane: coordinate, inspect, plan, review
  diffs, run tests, edit non-behavioral docs. When in doubt, delegate. Why: only the
  `www-hetzner-*` agents are briefed; you are not.

  | Task | Agent |
  |---|---|
  | Implement / refactor / debug behavior-relevant code | `www-hetzner-worker` (default) |
  | Write/extend tests | `www-hetzner-test-writer` |
  | Write/maintain POD | `www-hetzner-doc-writer` |
  | Commits, `Changes`, card → done, pre-release audit | `www-hetzner-release-manager` |

- **You cannot spawn subagents** (you ARE a `www-hetzner-*` agent): The delegation lock does
  not apply to you — implement, refactor, debug, and test per these rules.

Behavior-relevant = runtime behavior, the public API, the IO transport seam, the request/response
contract, error handling, tests, the CLI surface. Pure prose docs and README are not.

**Only `www-hetzner-release-manager` commits.** A worker leaves a commit-ready tree and hands
its card to `review`; you then dispatch the release-manager to cut the commit and close it.

## Coordination — karr board (always in scope)

`karr` is the internal board — git-native, state in `refs/karr/*`, one board per repo. Ticket
coordination is the orchestrating agent's job: use it, not the `kanban-issues-karr-coordination` skill.

- `karr list --compact` — open work · `karr show ID` — detail
- `karr create "Title" --priority high --body '…'` — new ticket
- `karr move ID in-progress --claim NAME` — start · `karr handoff ID --claim NAME --note "…"` — to review

A change to the `_build_request`/`_parse_response` shape affects `p5-net-async-hetzner`:
that is a **ticket on that repo's board**, never a silent cross-repo edit.

**Serialize board mutations when fanning out.** Keep implementation parallel if you like, but collect
the results and then loop `karr move`/`handoff`/`sync` sequentially — N at once is a resource event.

## Release — never without permission

`dzil build` / `dzil test` / `prove -lr t/` are fine anytime. `dzil release` and any
upload/tag/push are STRICTLY forbidden without the maintainer's explicit go-ahead — even if
a plan lists "release" as the next step. The local working-tree version is authoritative; a
lagging CPAN version is never a blocker and never a ticket. Heading toward release: stop and ask.

## Public issues — never act without instruction

GitHub carries real humans' bug reports under the maintainer's account; **karr** is the internal board.
Never list, read, comment on, edit, close or create a GitHub issue on your own initiative — only on explicit instruction.

## Hazards — the short form

- **The IO seam is load-bearing.** Every request goes `_build_request` → `io->call` →
  `_parse_response`; never call LWP directly from a controller.
- **Tests must never hit the network.** Extend a fixture instead — a live check against a real
  account can create or destroy real infrastructure.

## Perl / Moo / release specifics — reference, don't restate

Moo class and role patterns, the architecture, the `[@Author::GETTY]` POD and release conventions live in
skills `getty-perl-moo`, `www-hetzner-core`, `getty-perl-release-author-getty`, `perl-release-dist-ini`
(force-loaded for `www-hetzner-*` agents) — don't duplicate that here.
