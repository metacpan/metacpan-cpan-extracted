# ADR 0019 — Numbers are IEEE doubles, whatever the perl's NV and IV sizes

- Status: decided
- Date: 2026-11-16
- Tags: semantics, numbers, portability

## Context

Nunjucks numbers are JavaScript Numbers, i.e. IEEE 754 doubles (ADR 0007).
Perl's NV is whatever the perl was built with: a double on almost every
install, but `long double` (`-Duselongdouble`, archname `...-ld`) or
`__float128` (`-Dusequadmath`) on some CPAN smokers. There the shortest
round-trip search in `Lib->number_to_string` compared `0 + $sci == $abs` in the
wide type; past 17 digits no candidate matched, `$digits` stayed undef and
`{{ 1/3 }}` and `{{ 0.1 + 0.2 }}` rendered `0` (318 of 4623 tests failed).

A perl with a 4-byte IV (32-bit, no `use64bitint`) hit the same assumption from the
other side: `js_parse_int` for a power-of-two radix accumulates up to 2^58 and
masks and shifts it as a 64-bit integer (wrong results), and a JSON-decoded
integer beyond the IV range arrives as a string, which a test took for a String.

## Decision

A number in this port is a double on every perl. Where a number is created or
compared, a wide NV is rounded to double (`unpack 'd', pack 'd', $x`); the
shortest-round-trip comparison compares the double's bytes
(`pack('d', 0 + $sci) eq pack('d', $abs)`), not the wide values.

On a perl with `ivsize < 8` the power-of-two `parseInt` accumulation runs in
`Math::BigInt` (same algorithm, same bit operations); the test fixture decoder
turns bignums into doubles.

The extra work only runs when `$Config{nvsize} != 8`. On a double perl the
code path and the output are unchanged.

## Consequences

- `{{ 0.1 + 0.2 }}` renders `0.30000000000000004` on every perl.
- No wide-precision arithmetic is offered; there is nothing in JS to match it.
- Parsing a decimal string first yields a wide NV, then a double: a double
  rounding is theoretically possible for a decimal string within a hair of a
  midpoint. Not observed; the oracle corpus is the check.
