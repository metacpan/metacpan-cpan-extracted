# ADR 0015 — Environment loads built-in filters/tests/globals via a transitional guarded require

- Status: closed (superseded by ADR 0018, k19, 2026-11-13)
- Date: 2026-09-22
- Tags: environment, transitional, decision, k16, k17, k18, k19

## Context

Upstream `Environment` hard-`require`s its built-in bags at construction
(environment.js: `./filters`, `./tests`, `./globals`). Upstream can therefore
never have a missing built-in bag.

The Perl port lands these across several tickets: the built-in `is` tests came
forward with `Environment` (k16, `Text::Nunjucks::Tests`), but filters are
k17, globals are k18 (together with `Tests`), and the concrete loaders are k19. Between k16 and those, a
`use Text::Nunjucks::Filters` / `Globals` would fail to compile the whole
module.

`Environment::init` (`_load_builtin`, `Environment.pm:155-167`) therefore loads
each bag through a **guarded require** that swallows only the "module absent"
case (`Can't locate <that module>.pm`) and re-throws every other load error
(a syntax error in a bag that *does* exist still fails loud).

The current, oracle-confirmed effect: a fresh `Environment` ships with **no
filters and no globals**, so `{{ "x"|upper }}` raises filter-not-found and
`{{ range(3) }}` raises global-not-found, where upstream renders.

## Decision

Accept the guarded require as an explicit **transitional scaffold**, recorded in
the divergence ledger rather than only as an inline comment. Constraints:

- The swallow stays narrow: only the target module being absent is tolerated;
  any real load failure propagates.
- Each bag becomes an unconditional load (`use`) as its ticket lands — filters
  at k17, `Tests` and globals at k18, and the guard is removed once no built-in
  bag can be absent.

## Consequences

- Until the bags land, templates that depend on a built-in filter or global
  error instead of rendering. This is a known, temporary gap, not a semantic
  choice about how filters/globals behave.
- No behavioural divergence remains once all three bags exist: with filters,
  tests and globals present, the guarded require and a hard `use` are
  indistinguishable.
- This ADR is closed (superseded by the plain loads) when k18 and k19 land; the
  k18 and k19 tickets carry the pointer back here.

## Update (2026-11-13, k17)

Alignment of the ticket references; the decision above is unchanged. This
ADR first named globals as k17 work. The k17 run ports the filters only:
`Text::Nunjucks::Filters` is a hard `use` in `Environment` since k17, and the
guarded require no longer covers it. `Text::Nunjucks::Tests` (present since k16)
and `Globals` (k18, "Port tests.js + globals.js") still load through the guarded
require, so the guard stays until k18 lands, and the loaders (k19) follow.

## Update (2026-11-13, k18)

The guard is gone. `Text::Nunjucks::Globals` (globals.js) is ported, and with
`Filters`, `Tests` and `Globals` all present no built-in bag can be absent, so
`Environment` loads all three with a plain `use` and `init` calls their
`exports` / `exports` / `globals` directly; `_load_builtin`, the guarded
require, is removed. As the Consequences above say, nothing renders differently
for it: a fresh `Environment` now has upstream's `range`, `cycler` and
`joiner`, as upstream's does.

What this ADR still covers is k19: `init`'s server-side default,
`[new FileSystemLoader('views')]` when no loaders are given, waits for the
concrete loaders, so a fresh `Environment` still starts with no loader. The ADR
closes when k19 lands.

## Update (2026-11-13, k19)

Closed. The concrete loaders are ported (ADR 0018): `Environment.init` gives
an Environment without loaders upstream's server-side default,
`[new FileSystemLoader('views')]` (`Text::Nunjucks::Loader::FileSystem`), so a
fresh `Environment` starts with the loader upstream's does. Nothing
transitional is left in `init`: the built-in bags load unconditionally since
k18 and the default loader is in since k19. What remains of loader scope --
the out-of-scope `WebLoader` and `NodeResolveLoader`, chokidar `watch` -- is
decided in ADR 0018, not here.
