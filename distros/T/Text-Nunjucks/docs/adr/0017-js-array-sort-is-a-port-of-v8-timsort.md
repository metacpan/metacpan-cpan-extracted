# ADR 0017 — JS Array.prototype.sort is a port of V8's TimSort

- Status: accepted
- Date: 2026-11-13
- Tags: semantics, sort, v8, decision, k17

## Context

Upstream's `sort` and `dictsort` filters, and the Array `sort` member, end in
JavaScript's `Array.prototype.sort`. Since ES2019 that sort is required to be
stable, so every *consistent* comparator (one that orders any two elements the
same way every time and transitively) yields the same result in any stable
sort, Perl's included. Only an *inconsistent* comparator exposes which
algorithm V8 actually runs: mixed kinds under `sort` or `dictsort`, for example
`[1,'a',true,null]`, where the default comparator compares ToString values and
a user comparator may answer differently for the same pair. Measured with the
oracle, the `sort-mixed` case renders `,1,true,2,9,10,a` — a result no stable
sort of a consistent order produces. A second observable: `undefined`
elements go last and are never passed to the comparator
(`[undefined,'z','a'].sort()` is `a,z,` with the undefined last).

Two options:

1. Port V8's `Array.prototype.sort` as one `Lib` seam, pinned to the V8 of the
   oracle's Node. Any comparator, consistent or not, then sees V8's exact calls
   and leaves the array as V8 does.
2. Use Perl's stable `sort` and record a divergence limited to inconsistent
   comparators.

The recommendation was (1), but it ports V8 code rather than Nunjucks code, so
it was the maintainer's call.

## Decision

**Option (1).** Decided by the maintainer (Getty, 2026-11-13, k17 decision B):
the fidelity stance of ADR 0007 and ADR 0012 applies — "Aufwand ist immer ok" —
even though what is ported here is the engine under Nunjucks, not Nunjucks.

`Text::Nunjucks::Lib->js_array_sort($arr, $comparefn)` is the only
implementation of `Array.prototype.sort` in the distribution. It sorts `$arr`
in place and returns it; an undef `$comparefn` is JS `undefined`, the default
comparator. The Runtime Array `sort` member calls it, and so do the `sort` and
`dictsort` filters in `Text::Nunjucks::Filters` (k17). Nothing else sorts a JS
array.

It is a function-by-function port of V8 13.6.233.17's
`third_party/v8/builtins/array-sort.tq` — the V8 of node v24.19.0, the node the
oracle runs. TimSort with natural runs (a strictly descending run is
reversed), binary insertion sort up to the minimum run length, galloping merges
(`merge_lo` / `merge_hi`) with `min_gallop` adaptation, and the `merge_collapse`
invariant.

## Consequences

- **Spec prelude.** A `comparefn` that is neither undefined nor callable throws
  a `TypeError` first: `The comparison function must be either a function or
  undefined: X`, with X rendered as V8's NoSideEffectsToString does (Runtime
  `_js_no_side_effects_to_string`). Fewer than two elements are left untouched.
  The elements are copied to a work array, `undefined` ones are counted out,
  never compared, and written last. The comparator sees the unsorted receiver,
  and an exception leaves it untouched.
- **Comparators.** The default compares the JS ToString of both sides in UTF-16
  code-unit order (ADR 0012, `js_string_compare`). A user comparator is called
  `(x, y)` without `this`; its result goes through JS ToNumber, NaN counts as
  +0, and only a negative result orders x first.
- **Left out, deliberately.** The elements-kind accessors (Perl has one array
  kind), holes (the value model has none, ADR 0001), the Smi fast path of the
  default compare (same result), and the Smi clamps, overflow guards and
  temp-array size policy (Perl integers and arrays).
- **Pinning.** `maint/js-array-sort-fixtures` is a node script that refuses any
  V8 but 13.6.233.17 and is deterministic; it writes `t/data/js-array-sort.json`
  (1042 cases, 342,023 recorded comparator calls). `t/10-lib.t` replays the
  exact call sequences and results. A newer oracle node means comparing
  `array-sort.tq` again, re-porting what changed and re-pinning the fixtures.
- **Open items.**
  - ToString runs on every comparison, uncached, as in V8; that is slow for
    numbers (k85).
  - A blessed object as `comparefn` renders `#<Object>` in the TypeError; V8
    shows the constructor name (k44/k47 territory).
  - A function in a default sort prints its JS source in V8 (k44).
  - `toSorted` is not on the ADR 0008 surface yet (k84).
- Reversible only by a maintainer decision to accept option (2)'s divergence on
  inconsistent comparators.
