# WWW::PayPal House Rules

Apply to every task in this repository unless explicitly overridden. Bias: caution over
speed on non-trivial work; use judgment on trivial tasks. Loaded automatically at launch
(same priority as `CLAUDE.md`). Subagents get their discipline from the skills
force-loaded via `briefing.skills` — this file is for the orchestrating agent.

## Engineering discipline

1. **Think before coding** — State assumptions. When uncertain, ask rather than guess.
   Push back when a simpler approach exists. Stop when confused; name what's unclear.
2. **Simplicity first** — Minimum code that solves the problem. Nothing speculative. The
   distribution's scope is two use cases (one-off purchase, monthly subscription); a
   feature neither needs does not go in.
3. **Surgical changes** — Touch only what you must. Don't "improve" adjacent code,
   comments, or formatting. Match existing style.
4. **Surface conflicts, don't average them** — Contradicting patterns: pick one, explain
   why, flag the other for cleanup. Don't blend.
5. **Read before you write** — Before new code, read `Role::HTTP`, `Role::OpenAPI` and
   one existing controller/entity pair. Every controller looks the same on purpose.
6. **Tests verify intent** — A test that can't fail when the logic changes is wrong.
   Reproduce a bug before fixing it; leave the regression test behind.
7. **Fail loud** — "Done" is wrong if anything was skipped silently. "Tests pass" is
   wrong if any were skipped or if the run wasn't recursive.
8. **A red test is a claim before it is a failure** — Before changing code to turn a test
   green, say what the test asserts and whether your fix keeps that claim or replaces it.

## Delegation

This rule depends on whether the Agent/Task tool is available to you.

- **You can spawn subagents** (orchestrating main agent): do NOT touch behavior-relevant
  code yourself — delegate. Your lane: coordinate, inspect, plan, review diffs, run
  tests, manage git, edit non-behavioral docs. When in doubt, delegate. Why: only the
  agents below get their skills force-loaded via `briefing.skills`; you get no briefing
  and would touch internals with too little context.

  | Task | Agent |
  |---|---|
  | Implement / refactor / debug anything under `lib/`, `examples/` | `www-paypal-worker` (default) |
  | Write or extend tests in `t/` | `www-paypal-test-writer` |
  | POD, `Changes`, the consumer skill `perl-www-paypal` | `www-paypal-doc-writer` |
  | Pre-release audit | `www-paypal-release-checker` |
  | Payment/subscription flow design or review, webhooks, billing data model | `paypal-expert` |

- **You cannot spawn subagents** (you ARE one of the agents above): the delegation lock
  does not apply to you — implement, refactor, debug and test per these rules.

Behavior-relevant = anything under `lib/` and `t/`, the operation tables, the public API,
error handling, `cpanfile`, `dist.ini`. Prose docs and `Changes` notes are not.

## Coordination — karr board (always in scope)

Ticket coordination is the orchestrating agent's job, so `karr` is always in scope —
don't invoke the `kanban-issues-karr-cli` skill first, just use it. Git-native kanban; state lives in
`refs/karr/*`; this repo has its own board.

- `karr list --compact` / `karr board` — open work · `karr show ID` — detail
- `karr create "Title" --priority high --tags a,b` · `karr edit ID -a "note"`
- `karr move ID in-progress --claim NAME` · `karr handoff ID --claim NAME --note "…"`

**Serialize board mutations when fanning out.** Parallel implementation is fine; N
concurrent `karr move`/`handoff`/`sync` calls landing together is a resource event, not a
cheap command. Collect results, then loop the board writes sequentially.

## Release — never without permission

`dzil build` / `dzil test` / `prove -lr t/` are fine anytime. **`dzil release` and any
CPAN upload or tag push are STRICTLY forbidden without the maintainer's explicit
go-ahead** — even if a plan or ticket lists "release" as the next step. Stop and ask.

After any `dzil build`, run `dzil clean`: it leaves `.build/` and `WWW-PayPal-*/` behind,
and a build tree in the working directory is how stale copies get read as source.

## Public issues — never act without instruction

Two trackers, two universes. **karr** is the internal agent board, churned freely.
**GitHub `Getty/p5-www-paypal`** carries real users' bug reports and every write publishes
under the maintainer's name. Never act on a GitHub issue on your own initiative — not
listing, viewing, commenting, editing, closing or creating — unless the user explicitly
says to handle a specific one.

## Hazards specific to this repo

- **Tests must never reach PayPal.** No credentials, no network in `t/`. A live call
  against a live client id moves real money; against a sandbox id it silently pollutes
  the sandbox account with orders, products and plans that nobody cleans up. Recorded
  JSON payloads only; anything needing a token lives in `examples/`.
- **`.claude/skills/*/SKILL.md` are hardlinks.** `perl-www-paypal` is shared with
  `hiplatform` and `goldmine`; `perl-release-*` with ~76 projects. `Edit`/`Write`
  rewrite-and-replace, minting a fresh inode and silently freezing every other copy at
  the old content. Edit only with `cat > path <<'EOF'`, then verify with
  `stat -c '%i %h' path`. Full rules: skill `manage-skills`.
- **Sandbox and live ids are not interchangeable.** Product, plan, subscription and
  capture ids from one environment 404 in the other. Never put one in a code constant or
  a test fixture that could be mistaken for config.

## Conventions — reference, don't restate

Perl house style, Moo patterns, POD directives, `cpanfile` pinning, the next-version
scheme and the `Changes`/`{{$NEXT}}` handling live in skills `getty-perl-core`, `getty-perl-moo`,
`getty-perl-release-author-getty` and `perl-release-dist-ini`. The distribution's own
architecture is skill `www-paypal-core`; PayPal's domain model is `paypal-integration`.
Do not duplicate any of that content here.
