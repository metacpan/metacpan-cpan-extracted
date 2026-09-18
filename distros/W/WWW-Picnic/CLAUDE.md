# WWW::Picnic

Perl client for the Picnic Supermarket API. Distributed to CPAN as `WWW-Picnic`,
built with `[@Author::GETTY]` via `Dist::Zilla`. Library in `lib/WWW/Picnic/`,
CLIs in `bin/picnic*`, tests in `t/`.

## Delegation

Delegate behavior-relevant code to the right agent instead of touching it yourself —
principle and lane are in `.claude/rules/www-picnic-rules.md`.

| Task | Agent |
|---|---|
| Implement / refactor / debug behavior-relevant code | `www-picnic-worker` (default) |
| Write/extend tests | `www-picnic-test-writer` |
| Pre-release audit | `www-picnic-release-checker` |
| Write/maintain POD | `www-picnic-doc-writer` |

The agents carry their skills via `briefing.skills` (see `.claude/agents/`); the main
agent delegates rather than loading them. Skill sources live under `.claude/skills/`.

## Build & test

```bash
prove -lr t            # default suite (t/basic.t skipped — live API, off by default)
dzil build             # build the dist; never dzil release without permission
prove -lvr t/offline.t # MockUA-driven suite, fast
```

The live test runs only when both `TEST_WWW_PICNIC_USER` and `TEST_WWW_PICNIC_PASS`
are set; never set those in a fanned-out context — they mutate a real Picnic account.

## Project-specific bits

- `our $VERSION` lives **only** in `lib/WWW/Picnic.pm`; `[@Author::GETTY]` rewrites it
  via `version_finder = :MainModule`.
- `cpanfile` pins Getty-authored deps to their latest **released** CPAN version, never
  the repo `$VERSION` (the repo is always one ahead).
- `Changes` gets a bullet under `{{$NEXT}}` in the same change as any user-facing change.
