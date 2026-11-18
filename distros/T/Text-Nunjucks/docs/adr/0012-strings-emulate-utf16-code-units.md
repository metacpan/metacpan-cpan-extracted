# ADR 0012 — String operations emulate UTF-16 code units

- Status: accepted
- Date: 2026-09-22
- Tags: semantics, strings, unicode, decision, k5

## Context

JavaScript strings are sequences of UTF-16 code units. Measured with the oracle
on `'héllo😀'`: `length` → `7` (not 6 — the emoji is a surrogate pair, two code
units), `s[1]` → `é`, `reverse` splits the surrogate pair into two lone
surrogates. This affects `length`, `reverse`, `truncate`, `center`, `slice`/
indexing, `wordcount`, `batch` on strings, and any other length- or
index-sensitive string operation.

Two options: (a) Perl character semantics everywhere, recording an astral-plane
divergence (length 6, no lone surrogates — the more natural Perl behaviour); (b)
emulate UTF-16 code units, matching JS exactly including lone surrogates.

The initial recommendation leaned to (a) ("nobody wants lone surrogates"). The
**maintainer's explicit direction overrides that**: the same template must run
byte-identically in Perl and Node ("gleiche templates in perl und node halt
laufen"), maximum fidelity, cost accepted. A template computing
`{{ name|truncate(10) }}` or `{{ s|length }}` over an emoji must give the same
answer on both.

## Decision

**Option (b): string operations count and index in UTF-16 code units**, so they
match JS exactly. A code point above U+FFFF counts as two code units; `reverse`
and a `slice` that cuts through a surrogate pair produce lone surrogates, 1:1
with JS. The code-unit mechanism (a `js_string_length`, `js_substr`,
`js_char_at`, `js_reverse` family, or equivalent) lives in one place in
`Text::Nunjucks::Lib`, beside the other JS-semantics seams (`_strict_eq`,
`_falsy`, `js_whitespace_class`, the Number→String routine).

I/O contract: templates and context are **decoded character strings**, loaders
decode UTF-8, and `render` returns characters. Only the string *operations*
reckon in UTF-16 code units — the strings themselves stay ordinary Perl
character strings; the code-unit count is computed, not stored.

## Consequences

- `{{ 'héllo😀'|length }}` → `7`, `truncate`/`center`/`slice`/`wordcount`/`batch`
  cut at the same positions as Node, including around astral characters.
- A `reverse` or pair-splitting `slice` can produce lone surrogates — the 1:1
  behaviour, accepted for fidelity.
- More work than character semantics, accepted per the maintainer's direction.
- Related to ADR 0005 (JS regex classes) and ADR 0008 (native `.length`/`slice`
  on strings), which reckon in the same code units.
- Reversible only by a maintainer decision to accept an astral-plane divergence
  (option a); the corpus pins the UTF-16 cases in render mode once filters land.

## Implementation (k17)

How the decision was carried out; the decision above is unchanged.

- **Seams.** `Text::Nunjucks::Lib` holds `js_string_length`, `js_char_at`,
  `js_string_slice`, `js_substring`, `js_substr`, `js_string_index_of`,
  `js_string_last_index_of`, `js_split`, `js_string_compare` and
  `js_string_append`. Strings stay ordinary Perl character strings; the
  code-unit view is computed per call (an astral character is spelled as its two
  surrogate characters for the operation, and valid pairs are re-joined in the
  result).
- **Invariant.** No string the engine builds holds a valid surrogate pair as two
  surrogate characters; a pair is always the one astral character. Every join
  point — template `~` and `+`, String `concat` and `replace`, Array `join`,
  `repeat`, the output buffer, blocks, includes, extensions, `asyncAll` — goes
  through `js_string_append`, which re-pairs a lone high surrogate at the end of
  one string with a lone low surrogate at the start of the next, as JS
  concatenation does. So Perl `eq` and hash keys agree with JS `==`, `===` and
  object keys. A caller string that spells a pair as two surrogate characters is
  outside the invariant; the seams still treat both spellings alike.
- **Corpus.** Lone surrogates cannot travel through the oracle corpus JSON:
  Perl's JSON decoders reject `"\ud83d"`. `maint/corpus-regen` refuses a case
  that holds one, so they are tested indirectly (through a result that re-pairs
  or a length) or in Perl-side unit tests.
- **`js_reverse`.** Satisfied without a dedicated function: upstream's `reverse`
  filter is `split('')`, Array `reverse`, `join('')`, and each step is already a
  seam.
