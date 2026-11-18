# ADR 0010 — JS built-in Error/TypeError map to one generic name+message class

- Status: accepted
- Date: 2026-09-22
- Tags: semantics, lib, errors, decision

## Context

`lib.js` throws JS built-in errors: `new Error(...)` (e.g. `inOperator` on an
unexpected type) and `new TypeError(...)` (e.g. `groupBy`), and `_prettifyError`
rebuilds a plain `Error`. Perl has no JS `Error`/`TypeError`. The observable
surface is only the error's `name` and `message` — measured with the oracle,
`{{ 1 in 1 }}` prettifies to `(unknown path)\n  Error: Cannot use "in" operator
to search for "1" in unexpected types.` with the render error name `Template
render error`.

The k9 lib port encapsulated this in `Text::Nunjucks::Lib::Error` and flagged it
as an open mapping: one generic class vs a class per JS error type.

## Decision

**One generic `Text::Nunjucks::Lib::Error` class** with `name` (default
`'Error'`, overridable to `'TypeError'` or any JS error name) and `message`. No
class-per-JS-type hierarchy. `_prettify_error` reads `->name`/`->message`;
`TemplateError` adopts it as `cause`. This is what makes the prettified output
byte-identical to the oracle, and it is the single home for a "JS threw a
built-in error" value.

Distinct from `Text::Nunjucks::Lib::TemplateError` (the ported upstream
`TemplateError` class with `update()` for path/line/column), which is the
user-facing render error.

## Consequences

- Error output (name + message) is byte-identical to upstream; the JS error
  *type* is carried as the `name` string, which is all templates can observe.
- Adding a new JS error name later is a value (`name => '...'`), not a new class.
- If a future case needs behaviour keyed on the error type beyond its name, this
  is the one place to revisit.
