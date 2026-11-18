# ADR 0001 — Perl 5.40 minimum; JS value kinds come from the scalar, via builtin::

- Status: accepted
- Date: 2026-09-22
- Tags: semantics, dependencies, runtime

## Context

Nunjucks output depends on the runtime *kind* of a value in ways Perl
traditionally cannot see: `{{ 1 == 1 }}` renders `true`, `{{ '1' + 1 }}` is `11`
while `{{ 1 + 1 }}` is `2`, `1 === '1'` is false, the `number` and `string`
tests tell the two apart. A 1:1 port has to reproduce all of it.

Options were (1) Perl 5.40, where of these only `builtin::true` and
`builtin::false` are stable, while `builtin::is_bool` and
`builtin::created_as_number` are still experimental (the modules that use them
switch off the `experimental::builtin` warning); (2) Perl 5.36, same functions
but all experimental;
(3) an old minimum like the sibling dists, with wrapper objects for booleans and
numbers or `B`-flag heuristics.

## Decision

`requires 'perl', '5.040'`. A value's kind is read from the scalar itself with
`builtin::`. No wrapper classes for booleans or numbers, and never a
pattern-based guess (`looks_like_number`): a numeric *string* is a string.

## Consequences

- Narrower install base than the sibling distributions. Accepted: fidelity is
  the point of this distribution.
- Callers control kinds the way they do for JSON encoders: `0+$x` / `"$x"`.
  Data decoded by a JSON module arrives correctly flagged, except booleans,
  which may be `JSON::PP::Boolean` objects — normalised at the context boundary.
- All kind checks live in `Text::Nunjucks::Lib`; nothing else inspects flags.
