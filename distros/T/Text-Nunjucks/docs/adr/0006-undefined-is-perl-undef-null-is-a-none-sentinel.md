# ADR 0006 — JS undefined is Perl undef; JS null is a None singleton sentinel

- Status: accepted
- Date: 2026-09-22
- Tags: semantics, runtime, decision, k2

## Context

JavaScript has two empties, `undefined` and `null`; Perl has one, `undef`. The
distinction is observable (measured with the oracle):

| Template (`n` = JSON null, `u` = missing) | Upstream |
|---|---|
| `{{ u }}` / `{{ n }}` | both empty |
| `{{ u is defined }}` / `{{ n is defined }}` | `false` / `true` |
| `{{ n is none }}` / `{{ u is undefined }}` | `true` / `true` |
| `{{ n.foo }}` / `{{ u.foo.bar }}` | both empty, no error |
| `{{ a.b.c }}` with `throwOnUndefined` | error `attempted to output null or undefined value` |

So `is defined` alone forces the two to be distinguishable, and `none` (the
literal) must be a *value* that flows through `set`/macros/filters:
`{% set x = none %}{{ x is defined }}` → true.

Options were: (a) exists-based — a missing key is `undefined`, a present `undef`
is `null` — which breaks the moment a value leaves the lookup boundary (set,
macros, filters have no `exists`); (b) a `null` sentinel object, `undef` =
`undefined`; (c) collapse both and record the divergence, which loses `is
defined`.

## Decision

A single immutable **`None` sentinel** (one process-wide singleton, its home in
`Text::Nunjucks::Runtime`) represents JS `null`: the `none` literal, a JSON
`null`, and anything a caller means as "null". Perl `undef` represents JS
`undefined` (a missing key, an unset variable, a lookup that fell off the end).

- `is defined`: `None` → true, `undef` → false. `is none`: `None` → true.
  `is undefined`: `undef` → true.
- Rendering: both `None` and `undef` render to the empty string.
- `memberLookup` on either yields `undef` (JS `undefined`) with no error.
- `throwOnUndefined` fires for both.
- At the context boundary a JSON-decoded `null` is normalised to `None` (the way
  ADR 0001 normalises `JSON::PP::Boolean`), so data from a JSON module arrives
  correct. A caller who means "null" passes the `None` sentinel; a bare Perl
  `undef` in the context is `undefined`, not `null` — a documented convention.

The distinction lives in one place (`Runtime`), never re-derived per filter/tag.

## Consequences

- A value sentinel survives `set`/macros/filters where option (a) collapses, so
  `is defined`/`is none` stay 1:1 through the whole pipeline.
- Callers control the two empties the way ADR 0001 has them control kinds: pass
  `Text::Nunjucks::Runtime->None` (or the exported sentinel) for JS null.
- The corpus pins the table above in render mode once the runtime lands (k14).
