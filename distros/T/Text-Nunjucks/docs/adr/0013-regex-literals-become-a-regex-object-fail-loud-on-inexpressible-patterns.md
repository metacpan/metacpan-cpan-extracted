# ADR 0013 — Regex literals become a Regex object; inexpressible patterns fail loud

- Status: accepted
- Date: 2026-09-22
- Tags: semantics, runtime, regex, decision, k7

## Context

The lexer produces regex tokens whose value is `{body, flags}` (ADR/ticket flow
k10), the oracle AST dumps a regex as `{regex, flags}`, and templates use regexes
via `.test()` and the `replace` filter. JS regex flags are `g`, `i`, `m`, `y`.
JS and Perl regex syntax differ (named groups, `\d`/`\s`/`\w` semantics — see
ADR 0005, lookbehind, `$` vs `\z`).

## Decision

- **Runtime value**: a regex literal becomes a blessed
  `Text::Nunjucks::Runtime::Regex` object exposing the members a template calls
  on it — `test`, `exec`, `source`, `flags`, `global` — because `r/…/.test(s)`
  reaches them through `member_lookup`/`callWrap` (ADR 0008/0009), so it must be
  an object with methods, not a bare `qr//`.
- **Flags**: `i` → `/i`, `m` → `/m`, `y` (sticky) → `\G`-anchored matching, `g`
  → carried on the object and honoured by `test`/`replace`/global matching (not
  a `qr//` flag). Perl regexes always compile with the ADR 0005 character-class
  discipline (`\s`/`\d`/`\w` as explicit ECMAScript sets), not bare Perl classes.
- **Pattern translation**: the JS `body` becomes a `qr//` for the common case
  (most patterns are compatible). A construct Perl cannot express faithfully
  (certain lookbehind, JS-only named-group syntax, …) **fails loud at the time
  the regex literal is compiled**, with a clear message — never a silent
  mistranslation.
- Mechanism (translation + the Regex object) lives in one place (Runtime/Lib),
  grown on demand and oracle-verified.

## Consequences

- `{{ r/^h.l/.test(s) }}` and `s|replace(r/…/g, …)` work through the Regex
  object's methods.
- Patterns Perl cannot express are a compile-time error, not a wrong match — the
  fail-loud house rule.
- The set of translated constructs grows on demand; each is oracle-verified.
- Ties into ADR 0005 (regex character classes) and ADR 0008 (member access).
