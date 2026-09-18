# WWW::Picnic House Rules

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
5. **Read before you write** — before new code, read the caller in `WWW::Picnic`, the
   matching `WWW::Picnic::Result::*` class, and the `MockUA` sample generator for that
   endpoint. "Looks orthogonal" is dangerous.
6. **Surface conflicts, don't average them** — pick one pattern, explain why, flag the
   other for cleanup.
7. **Checkpoint after every significant step** — done / verified / left.
8. **Fail loud** — "done" is wrong if anything was skipped silently.

## Delegation

This rule depends on whether the Agent/Task tool is available to you.

- **You can spawn subagents** (orchestrating main agent): do NOT touch behavior-relevant
  code yourself — delegate to this repo's worker. Your lane: coordinate, inspect, plan,
  review diffs, run tests, manage git, edit non-behavioral docs. When in doubt, delegate.
  Only the `www-picnic-*` agents get their skills force-loaded via `briefing.skills`; you
  get no briefing and would touch internals with too little context.

  | Task | Agent |
  |---|---|
  | Implement / refactor / debug behavior-relevant code | `www-picnic-worker` (default) |
  | Write/extend tests | `www-picnic-test-writer` |
  | Pre-release audit | `www-picnic-release-checker` |
  | Write/maintain POD | `www-picnic-doc-writer` |

- **You cannot spawn subagents** (you ARE a `www-picnic-*` agent): the delegation lock
  does not apply to you — implement, refactor, debug, and test per these rules.

Behavior-relevant = runtime behavior, the public API (`WWW::Picnic`, `::Result::*`), auth
and 2FA flow, search/cart/article endpoints, CLI commands, error handling, tests,
performance. Pure prose docs and `Changes` notes are not.

## Release — never without permission

`prove -lr t` and `dzil build`/`dzil test` are fine anytime. `dzil release` and any CPAN
upload are STRICTLY forbidden without the maintainer's explicit go-ahead — even if a plan
or STATUS document lists "release" as the next step. For anything heading toward release:
stop and ask. Use the `www-picnic-release-checker` agent for the pre-release audit.

## Public issues — never act without instruction

Two trackers, two universes. CPAN carries real humans' RT tickets, written under the
maintainer's account. Never act on a CPAN RT issue on your own initiative — not even to
read it. No listing, viewing, commenting, editing, closing, or creating unless the user
explicitly says to handle a specific ticket.

## Project-specific hazards

- **Live API test hits a real account.** `t/basic.t` runs only when `TEST_WWW_PICNIC_USER`
  + `TEST_WWW_PICNIC_PASS` are set; never set those env vars in a fanned-out or parallel
  context. The test mutates state (it can call `clear_cart` and login flows) and would
  touch the real Picnic account of whoever's credentials are present.
- **Auth token lives on the instance.** `_auth_cache` is `ro` with a default `sub {{}}`
  — there is exactly one auth token per `WWW::Picnic` object. Reusing an instance across
  threads is unsafe; one client per logical session.
- **Search endpoint shape changed.** The live API returns a nested
  `body.child.children[].child.children[].sellingUnit` shape; do not "simplify" the
  parser in `WWW::Picnic::Result::Search` without re-checking against a real response
  and updating the `sample_search_response` fixture.
- **2FA is interactive.** `verify_2fa_code($sms_code)` is the only way past a
  `requires_2fa` login; the CLI prompts on `<STDIN>`. Anything scripted against a 2FA
  account must surface that prompt or the user will hang silently.
- **Test runner trap.** Plain `prove -l t/` is non-recursive; always use `prove -lr t`
  so any future subdir tests are never silently skipped (the suite is flat today, keep
  `-r` anyway).

## Perl specifics — reference, don't restate

Module loading, Moo patterns, dependency pinning, `[@Author::GETTY]` release metadata,
POD directives, and house style live in skills `getty-perl-core`, `getty-perl-moo`,
`perl-release-dist-ini`, `getty-perl-release-author-getty`, and `www-picnic-perl`
(force-loaded for `www-picnic-*` agents). Do not duplicate that content here.
