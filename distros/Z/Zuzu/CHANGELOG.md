# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project roughly adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html),
but using Perlish version numbers like `x.yyyzzz` instead of `x.y.z`.

## 0.006000 - 2026-06-19

### Fixed

- The `?:` operator now preserves any defined left-hand value and falls back
  only when the left-hand value is null, instead of using truthiness.
- `Path.tempfile()` and `Path.tempdir()` now attach lifecycle cleanup to the
  returned `Path` object, deleting temporary files and recursively deleting
  temporary directories when `__demolish__` would run.

## 0.005000 - 2026-06-17

### Added

- `switch` case values can now override the switch comparator with a
  comparison operator prefix, such as `case ~ /^Rob/` or `case eqi "Bob"`.
- Added shared conformance coverage for dynamic method calls whose method
  expression evaluates to either a method name or a Method value, including
  named arguments and `std/eval`.
- Added logical operators `nor`/`⊽`, `xnor`/`↔`, `onlyif`/`⊨`,
  `butnot`/`⊭`, plus the value-preserving `and?`/`⋀?`, `or?`/`⋁?`,
  `xor?`/`⊻?`, `xnor?`/`↔?`, `nand?`/`⊼?`, `nor?`/`⊽?`,
  `onlyif?`/`⊨?`, and `butnot?`/`⊭?` variants.
- `std/path/zz` ZZPath expressions now recognise and evaluate the new
  language operators for bit shifts, divisibility, logical combinations, and
  value-preserving logical combinations.

### Fixed

- Boolean `and`/`⋀` now returns a Boolean value instead of returning the raw
  right operand.
- `std/marshal` and its CBOR validator no longer depend on `POSIX`
  exporting `isfinite`, fixing load failures on older Perl/POSIX module
  combinations.
- Collection parity fixes: `Array.join()` now supports an unstringable-value
  substitute or callback, `PairList.enumerate()` returns an Array of pairs, and
  `Bag.remove()` removes every matching value while `remove_first()` removes
  only one. Arrays now also expose `to_Array()` and `slice()`, Dicts expose
  `contains()`, Dict, Bag, and PairList expose `is_empty()`, and Bag/Set
  expose `push_weak()` as an alias for `add_weak()`. `Array.get()` now requires
  an index, `get()`/`set()`/`set_weak()` count negative indexes from the end,
  Array callback methods reject missing or extra callback arguments, and
  `sample()`/`shuffle()` return randomised non-mutating results.
- Bare wordlike named-argument keys such as `length: 42` now parse like
  the same unquoted keys in Dict and PairList literals.
- TZ-dependent Perl runtime tests now skip their timezone-sensitive cases when
  `TZ` is not set.
- The Perl HTTP async overlap integration test now checks server-side
  connection overlap instead of relying on a tight total wall-clock threshold.

## 0.004000 - 2026-06-12

*stdlib tag 20260612, languagetests tag 20260612.*

### Added

- Added README.md.
- std/net/url's `fill_template` is now a complete RFC 6570 URI
  Template implementation (all operators, `:N` prefix and `*` explode
  modifiers, list and associative values), implemented with
  URI::Template plus strict template validation, and validated against
  the official URI Template test suite. Invalid templates throw.
- New divisibility operators: `a ∣ b` (U+2223; ASCII alias `divides`,
  a new keyword) is a Boolean test that the left operand exactly
  divides the right; `a ∤ b` (U+2224, no ASCII alias) returns the
  Number `b mod a`, truthy exactly when the left operand does not
  divide the right. Both coerce operands to Number and sit at the
  comparison precedence tier.
- `for` loops (including postfix `for`) iterate over the characters of a
  String (each a 1-character String) and the bytes of a BinaryString
  (each a 1-byte BinaryString).
- Bitshift operators `<<`, `>>`, `«`, `»`. Numbers shift arithmetically
  (operands truncated to integers; negative shift counts throw).
  BinaryStrings shift as one whole bit string: bits carry across byte
  boundaries, length is preserved, vacated bits are zero. Shifts bind
  tighter than bitwise `&`/`|`/`^` and looser than additive operators;
  inside a set literal the closing `>>`/`»` still terminates the
  literal.
- Numeric literals: uppercase-E exponents (`1E3`, `2.5E-7`), hex
  (`0x1F`), binary (`0b1111`), and octal (`0o100`) with lowercase
  prefixes. Lowercase `1e3` and uppercase `0X`/`0B`/`0O` prefixes remain
  invalid in source, but String-to-Number coercion accepts either case
  for the exponent marker and radix prefixes.
- New `std/string/encode` module: `encode(String, encoding)` /
  `decode(BinaryString, encoding)` with UTF-8, UTF-16, UTF-32, and
  ISO-8859-1 codecs plus `ENCODING_UTF8`/`ENCODING_UTF16`/
  `ENCODING_UTF32`/`ENCODING_LATIN` constants. Encoding names match
  case-insensitively; UTF-16/UTF-32 encode big-endian without a BOM and
  decode honours a leading BOM.
- `std/string` exports `to_binary` and `to_string`.
- `std/string/encode` also accepts any encoding known to Perl's Encode module.

### Changed

- `mod` now uses float remainder semantics (POSIX fmod), matching
  zuzu-rust and zuzu-js: non-integer operands work and the result
  takes the sign of the dividend. Previously operands were truncated
  to integers and negative results followed the divisor's sign.

### Fixed

- `std/math/bignum` now returns String values from `BigNum.to_dec` and
  `BigNum.to_String` consistently; use `BigNum.to_Number` for numeric
  conversion.
- std/data/json `decode` no longer returns null for JSON text
  containing non-ASCII characters (the JSON::Tiny backend is now fed
  escaped input, as decode_binarystring already did).
- `Path.slurp_utf8`, `Path.slurp_utf8_async`, and `Path.lines_utf8` use a
  lax UTF-8 decode (like `readline_utf8` already did), so files containing
  well-formed sequences for noncharacter code points such as U+10FFFE can
  be read, matching zuzu-rust and zuzu-js. The strict decode previously
  died with "Can't interchange noncharacter code point".
- Fix warning on Perl 5.43.x caused by backslash within `qw()`.
- `std/math/bignum` now produces exact decimal text for integer `bpow`
  with integer operands (for example, `BigNum.from_dec("10").bpow(1000)`
  now yields `10` with 1000 zeros, rather than floating-point drift).

## 0.003000 - 2026-06-10

*stdlib tag 20260610, languagetests tag 20260610.*

### Changed

- Bumped version to 0.003000.

### Fixed

- Fixed class field initializer evaluation so default values are evaluated in the
  class’s declaration environment, resolving missing-module-constant lookups.

### Added

- Added shared conformance coverage for dot syntax as method calls, including
  rejection of direct method/function call lvalues and continued support for
  assigning into collections returned from calls.

## 0.002000 - 2026-06-08

*stdlib tag 20260608, languagetests tag 20260608.*

### Changed

- Bumped the distribution and module versions to 0.002000.
- Updated the `languagetests` submodule with statement-termination and
  postfix-return conformance coverage.

### Fixed

- Cleaned up native DBI handles during runtime finish to avoid intermittent
  DBD::SQLite crashes at Perl interpreter teardown.
- Normalized XML module text values so parsed, loaded, serialized, and
  attribute/text accessor values consistently use decoded text.

## 0.001005 - 2026-06-05

### Changed

- Updated the `docs/userguide` and `languagetests` submodules.

### Fixed

- Fixed string indexing to return one-character strings, including negative
  indexes.
- Added BinaryString index and slice assignment support.

## 0.001004 - 2026-06-05

### Changed

- Raised the required versions of Path::Tiny and Sub::Quote.
- Marked the std/clib integration test as author-only.
- Excluded `blib` from distribution manifests.

### Fixed

- Fixed the marshal golden fixture test to parse on older supported Perl versions.

## 0.001003 - 2026-05-31

### Changed

- Bumped required version of CryptX.

## 0.001002 - 2026-05-29

### Changed

- Skipped some tests which should be author-only, using the AUTHOR_TESTING environment variable.

### Fixed

- Fixed various test cases that were based on outdated assumptions.

## 0.001001 - 2026-05-29

### Removed

- Remove redundant testing-related files from `t/` where there are newer version in `stdlib/`.
- Remove the outdated Zuzuzoo and Zuzuzoo::CLI modules.

## 0.001000 - 2026-05-29

*First release.*
