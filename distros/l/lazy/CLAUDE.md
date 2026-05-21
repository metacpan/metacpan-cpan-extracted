# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this project is

`lazy` is a single-file Perl module (`lib/lazy.pm`) that auto-installs missing CPAN modules at `require`-time via `App::cpm`. There is no broader application — the entire feature surface is one `import()` method that pushes a code-ref hook onto `@INC`.

## Build / test / lint

This is a Dist::Zilla distribution managed by the `[@Author::OALDERS]` plugin bundle (see `dist.ini`).

- Build: `dzil build`
- Run all tests: `dzil test`
- Run a single test (no dzil overhead): `prove -lv t/load.t`
- Author / release tests: `dzil xtest` or `RELEASE_TESTING=1 AUTHOR_TESTING=1 dzil test`
- Install dev deps: `dzil authordeps --missing | cpm install -g -` then `dzil listdeps --develop --missing | cpm install -g -`
- Regenerate cpanfile / Makefile.PL after editing `dist.ini`: `dzil regenerate`
- Lint / tidy: `precious lint --all` (check), `precious tidy --all` (auto-fix). Configs live in `perltidyrc`, `perlcriticrc`, `perlimports.toml`; rule wiring is in `precious.toml`. `precious` itself plus `omegasort` (used to sort `.gitignore`) are Rust binaries — install via `ubi` or `cargo install`.
- Release: `dzil release`

`t/local-install-via-args.t` performs a live install against `cpan.metacpan.org` and `cpanmetadb.plackperl.org` — it needs internet and may be slow. `t/load.t` is the fast smoke test.

## Generated files — do not edit directly

`cpanfile`, `Makefile.PL`, and `META.json` are regenerated from `dist.ini` by Dist::Zilla. Edit `dist.ini` (or the upstream `Dist::Zilla::PluginBundle::Author::OALDERS` plugin list) and run `dzil regenerate`. Use `-remove = PluginName` in `dist.ini` to drop plugins inherited from the bundle (existing examples on lines 8–10).

## How the module works (architecture)

`lazy::import` is the only meaningful code path. It:

1. Walks `@INC` looking for a code-ref already named `_lazy_worker` (via `Sub::Identify::sub_name`) and returns early if found, so `use lazy` is idempotent across re-imports.
2. Parses `-L <dir>` / `-g` out of the import args using `Getopt::Long` in `pass_through` mode. Remaining args are forwarded verbatim to `App::cpm`. Default behavior is a global install (`-g`); `-L` triggers a `require local::lib` and a runtime `local::lib->import(...)` so the install lands in the requested directory.
3. Builds an anonymous sub that calls `App::cpm::CLI->run('install', @args, $module_name)`, names it `_lazy_worker` via `Sub::Name::subname`, and pushes it onto `@INC` followed by a copy of the original `@INC`. The trailing copy is what gives Perl a second chance to `require` the module after install succeeds.
4. The hook itself uses a `state %seen` counter to bail after one retry per module (recursion guard), and hard-skips a few known-bad patterns: `auto::*.al`, `Net::DNS::Resolver::*`, `Encode::ConfigLocal`. When extending the skip list, follow the existing pattern of an early `return 1` (which tells Perl "I handled it, stop searching `@INC`") rather than `return` / `return 0`.

Two non-obvious constraints worth preserving:

- The named-sub trick (`subname '_lazy_worker', $_lazy`) exists so `import` can detect an already-installed hook. Renaming the sub will break idempotency.
- Output is suppressed under `$ENV{HARNESS_ACTIVE}` so test harnesses don't see the emoji status lines. Keep new user-facing prints behind that same guard.

## Tests

`t/test-data/darkpan` is a tiny CPAN-style mirror used by `t/local-install-via-args.t` to install `Local::StaticInstall` without touching the real network for the resolution step (it still talks to cpan.metacpan.org for the actual fetch). When adding new install-path tests, prefer adding a fixture under `t/test-data/darkpan` over hitting public CPAN.

## CI

`.github/workflows/test.yml` runs three jobs in `perldocker/perl-tester:5.42`:

1. `build-job` — `auto-build-and-test-dist` with all author/release env vars on, uploads `build_dir` artifact.
2. `coverage-job` — installs deps from the built tarball and runs `test-dist` with `CODECOV_TOKEN`.
3. `test-job` — matrix of Perl 5.24 → 5.42 on `ubuntu-latest`, installs from `cpanfile` via `perl-actions/install-with-cpm`, runs `prove -lr t` with `AUTHOR_TESTING=0 RELEASE_TESTING=0`.

The matrix step deliberately runs only end-user tests, so author-only failures (POD, spelling, precious) won't block PRs across old Perls — they're caught in `build-job` and `lint-job` instead.

A standalone `lint-job` runs `precious lint --all` against the working tree on `ubuntu-latest` inside `perldocker/perl-tester:5.42`. It uses `oalders/install-ubi-action` to install `ubi`, `omegasort`, and `precious` from GitHub releases, then `cpm install` for the Perl-side tools (`App::perlimports`, `Perl::Critic`, `Perl::Tidy`). It does not depend on `build-job` and runs in parallel.
