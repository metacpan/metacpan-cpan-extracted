# ADR 0005 — JS regex character classes map to explicit ECMAScript sets, flag-independent

- Status: accepted
- Date: 2026-09-22
- Tags: semantics, lexer, regex, unicode

## Context

The engine's own implementation uses regexes with `\s` / `\d` / `\w` — for
example the lexer's `lstripBlocks` test `/^\s+$/` (`lexer.js:295`). These are
*engine-internal* regexes, not user-facing regex literals (`r/.../`, which are
ticket k7).

JavaScript's `\s` matches a fixed Unicode set that includes U+00A0 (NBSP) — a
member of the lexer's own `whitespace_chars` (`lexer.js:5`). Perl differs in a
way that is both wrong and *non-deterministic across inputs*:

- Default `/d` semantics make Perl `\s` match U+00A0 **only when the target
  string's SV carries the UTF-8 flag**. The same logical template then lexes
  differently depending on how it reached the engine (a byte/Latin-1 string, a
  `"\x{a0}"` literal, or a decoded-UTF-8 string). Measured with the oracle:
  `{"opts":{"lstripBlocks":true},"template":"x\n  {% t %}"}` strips the
  NBSP run upstream; the port left it in place unless the SV was upgraded.
- Even Perl `\s` under `/u` is not JS `\s`: it diverges at U+0085 and U+FEFF.

A bare Perl `\s` mapped inline for JS `\s` is therefore not 1:1, and the
divergence reaches rendered output (leftover whitespace under `lstripBlocks`).
Under ADR 0004 the oracle decides; under the porting contract a difference
without an ADR is a bug.

## Decision

A JavaScript regex character class used in the engine's own regexes is mapped to
its **explicit ECMAScript code-point set**, matched **flag-independently** (an
explicit character class under `/u`, never a bare `\s`/`\d`/`\w`). The sets live
in one place — `Text::Nunjucks::Lib` — as a named helper/constant per class, and
are added on demand: `\s` now (the only one the lexer needs); `\d` and `\w` when
the parser or filters first need them. Each set's exact membership is verified
against the oracle / ECMAScript definition, never written from memory.

This is the same discipline ADR 0001 applies to value kinds and that `Lib`
already applies to JS `===` (`_strict_eq`) and JS truthiness (`_falsy`): each JS
semantic has exactly one seam in `Lib`.

## Consequences

- Lex / parse / filter behaviour is identical regardless of the UTF-8 flag state
  of the template SV — the `/d`-dependence is gone.
- One home (`Lib`) for JS regex character classes; `Lexer` and later modules call
  the helper instead of re-deriving `\s` inline.
- The sets grow on demand; every addition is oracle-verified, so an exotic
  code-point (U+2028, U+FEFF, …) is either in the committed set or not by
  measurement, not by guess.
- User-facing regex literals `r/.../` are a separate concern (k7); this ADR is
  only about the engine's internal regexes.
- Related to but distinct from k5 (UTF-16 vs Perl characters): k5 governs string
  length/indexing/reverse, this governs regex class membership. If k5's decision
  reshapes string handling, re-check that these sets still match the oracle.
