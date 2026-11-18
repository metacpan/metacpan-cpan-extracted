# ADR 0007 — One shortest-round-trip Number→String routine; JS operators in Runtime

- Status: accepted
- Date: 2026-09-22
- Tags: semantics, runtime, numbers, decision, k4

## Context

ADR 0001 fixed value *kinds*; this settles how numbers are formatted and
computed. Measured with the oracle:

- Number→String: `1/3` → `0.3333333333333333`, `0.1+0.2` →
  `0.30000000000000004`, `1e21` → `1e+21`, `10/4` → `2.5`, `1/0` → `Infinity`,
  `'a'*2` → `NaN`. Perl's default stringification (`%.15g`) does **not** match —
  it renders `0.1+0.2` as `0.3`.
- Operators: `+` is add or concat depending on operand kinds (ADR 0001),
  `7 // 2` → `3` (floor division), `2 ** 0.5` → `1.4142135623730951`, mixed
  comparison follows JS (`'10' < '9'` true, `10 < 9` false, `1 == '1'` true,
  `1 === '1'` false).
- Filters follow the JS built-ins: `'3.7'|int` → `3`, `'x'|int` → empty,
  `'3.7abc'|float` → `3.7`, `2.5|round` → `3`, `-2.5|round` → `-2` (Math.round).

## Decision

**One Number→String routine in `Text::Nunjucks::Lib`** reproducing ECMAScript
`Number::toString`: the shortest decimal that round-trips to the same double
(try `%.1g`…`%.17g`, take the first that parses back equal), then apply JS's
exponent thresholds and the spellings `Infinity` / `-Infinity` / `NaN`. Every
number reaching output goes through it; nothing uses bare `"$n"`.

**The JS operators live in `Text::Nunjucks::Runtime`**, one home each: `+`
(add-or-concat by kind), `-`/`*`/`/`, `//` (floor), `%`, `**`, and the loose/
strict comparisons (building on ADR 0001's `is_bool`/`created_as_number` and
`Lib`'s `_strict_eq`). `int`/`float` follow `parseInt`/`parseFloat`; `round`
follows `Math.round`.

The maintainer has accepted the implementation cost ("aufwand ist immer ok"):
byte-identical numeric output is the point of this distribution.

## Consequences

- `{{ 0.1 + 0.2 }}` renders `0.30000000000000004`, `{{ 1/3 }}` renders
  `0.3333333333333333`, `{{ 1/0 }}` renders `Infinity` — identical to Node.
- Perl's own float model still bounds precision (a double is a double); the
  routine reproduces JS *formatting* of that same double, not extra precision.
- The corpus pins the measured cases in render mode once the runtime lands (k14).
- Big-integer literal text beyond double range (k12 finding, ticket note on k4)
  is governed here: it follows Perl's double model exactly as JS follows its own;
  a corpus case for oversized ints may be committed once this is implemented.
