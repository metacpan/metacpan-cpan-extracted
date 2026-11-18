# ADR 0008 — Native JS methods from templates are a curated, in-place emulated surface in Runtime

- Status: accepted
- Date: 2026-09-22
- Tags: semantics, runtime, member-lookup, decision, k6

## Context

Upstream `memberLookup` (`runtime.js`) is a raw `obj[val]`: any property or
method of the underlying JS value is reachable from a template, and a method
comes back as a closure bound to its owner. Measured with the oracle:
`s.toUpperCase()` → `ABC`, `arr.join('-')` → `1-2-3`, `arr.length` → `3`,
`s.length`, `arr.indexOf(1)` → `1`, `s.replace(...)`, `s.slice(1,3)`,
`n.toFixed(2)`. Calling a missing member throws
`Unable to call \`x\`, which is undefined or falsey`. A member call rebinds
`this` to the owner (`{{ foo.bar() }}` returns `this.baz`); a bare call binds
`this` to the Context.

No portable upstream test *forces* any of these to work at render time — the
test suite only asserts they parse, plus one user-method `this`-binding. So the
emulated surface is a porting choice; the maintainer's direction is maximum
fidelity ("gleiche templates in perl und node"), cost accepted.

A Perl scalar/array has no such members, so the surface is emulated.

## Decision

A **curated set of emulated String / Array / Number methods** lives in one
place, `Text::Nunjucks::Runtime::member_lookup` (never re-derived elsewhere):

- **Always** `.length` on strings and arrays.
- **String**: `toUpperCase`, `toLowerCase`, `trim`, `replace`, `slice`,
  `substring`, `split`, `indexOf`, `charAt`, `concat`, … (grown on demand,
  each verified against the oracle).
- **Array**: `join`, `indexOf`, `slice`, `concat`, `length`, and the mutators
  `push`, `pop`, `shift`, `unshift`, `sort`, `reverse` — which **mutate the
  underlying Perl structure in place**, reproducing JS reference semantics 1:1
  (oracle: `{% set r = arr.push(4) %}` returns the new length *and* the context
  array is mutated).
- **Number**: `toFixed`, … as needed.
- Both `this` regimes: a bare call binds the Context, a member call binds the
  owner object.
- A missing/non-function member call fails loud with the exact upstream text
  (`Unable to call \`x\`, which is undefined or falsey` / `which is not a
  function`).

No attempt is made to mirror the *entire* JS prototype chain — only the members
real templates use. jinja-compat (k22) layers its Python-style surface on top
separately.

## Consequences

- Real-world templates that call `str.trim()`, `arr.join(...)`, `.length` work
  and match Node byte-for-byte.
- In-place mutation matches upstream (emergent JS reference semantics, untested
  upstream) — chosen for fidelity per the maintainer's direction.
- The set is extended on demand; each addition is an oracle-verified corpus case
  (render mode, once the runtime lands in k14), not a guess.
- String indexing/`.length`/`slice` interact with the UTF-16 question (k5) —
  their code-unit vs character behaviour follows that decision.

## Surface as of 2026-11-13

The decision above is unchanged; this is the inventory the code carries today.
The tables are `%STRING_METHODS`, `%ARRAY_METHODS` and `%NUMBER_METHODS` in
`Text::Nunjucks::Runtime`, reached through `member_lookup` (property reads) and
`member_lookup_method` (call sites, ADR 0016). The "…" and "as needed" in the
lists above are now concrete:

- **`.length`**: strings (counted in UTF-16 code units, ADR 0012) and arrays.
  Plain strings also have index access (`s[0]`); a SafeString has `length` and
  the methods but no index access.
- **String**: `toUpperCase`, `toLowerCase`, `trim`, `replace`, `slice`,
  `substring`, `substr`, `split`, `indexOf`, `lastIndexOf`, `charAt`,
  `concat`. A SafeString exposes the same methods on its value.
- **Array**: `join`, `indexOf`, `lastIndexOf`, `slice`, `concat`, `filter`,
  `reduce`, and the in-place mutators `push`, `pop`, `shift`, `unshift`,
  `sort`, `reverse`. `sort` runs through `Text::Nunjucks::Lib::js_array_sort`
  (ADR 0017), the same seam the `sort` and `dictsort` filters use.
- **Number**: `toFixed`.
- **Regex** (outside the String/Array/Number tables): `test` and `exec` at call
  sites; `source`, `flags` and `global` are properties.

Known missing members, each tracked on a card and not yet emulated:

- Array `toSorted` (k84) and `splice` (k86).
- Array `map` (k70).
- Template-level `toString` (k70).

A call to any of these fails loud with the upstream text, as for every
member outside the surface.
