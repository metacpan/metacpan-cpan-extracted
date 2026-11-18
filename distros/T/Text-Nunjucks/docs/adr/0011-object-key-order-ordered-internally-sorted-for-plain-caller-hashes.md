# ADR 0011 — Object key order: insertion-ordered internally, sorted for plain caller hashes

- Status: accepted (amended 2026-11-13 — see "Amendment 2026-11-13")
- Date: 2026-09-22
- Tags: semantics, runtime, ordering, dependencies, decision, k3, k51

## Context

JS objects iterate in insertion order; Perl hashes do not. Observable upstream
(oracle): `{% for k, v in {b:1, a:2} %}` → `b=1;a=2;`, `dump` →
`{"b":1,"a":2}`, `dictsort|join(',')` → `a,2,b,1`. This touches `for k,v`,
`dump` (JSON.stringify), `list`, `dictsort`, `items`/`keys` (jinja-compat), and
dict literals in templates.

The maintainer's direction is maximum fidelity with new dependencies welcome
("gern neue requirements wenn die dir arbeit abnehmen").

## Decision

Combined (a)+(b):

- **Template dict literals and everything the engine builds** use an
  **insertion-ordered** hash representation, so `{b:1, a:2}` iterates `b` then
  `a` — byte-identical to JS. The representation is **`Hash::Ordered`** (a new
  runtime dependency; fast, no `tie` overhead).
- **Caller-supplied plain Perl hashes** have no order to preserve, so they
  iterate **sorted by key** — a deterministic, documented divergence (the only
  place Perl cannot match JS insertion order because the information was never
  there).
- **Caller-supplied ordered hashes** (`Hash::Ordered`, or a `Tie::IxHash`-tied
  hash) are honoured in their own order. *Superseded by the 2026-11-13
  amendment, see "Caller-supplied ordered hashes" (pending maintainer
  confirmation): `Hash::Ordered` follows the JS rule over its own order, and
  `Tie::IxHash` is not honoured at all (known gap, k78).*

The ordering mechanism lives in one place (Runtime/Lib), used by every
order-sensitive operation (`for`, `dump`, `list`, `dictsort`, `items`, `keys`).

## Consequences

- `Hash::Ordered` joins the cpanfile as a runtime dependency.
- Template-authored and engine-built objects are 1:1 with JS; a caller who needs
  a specific order passes an ordered hash, exactly as they would for a JSON
  encoder.
- Plain caller hashes render deterministically (key-sorted); this is the one
  documented key-order divergence, and it is unavoidable.
- The corpus pins the measured cases (`for`, `dump`, `dictsort`) in render mode
  once the runtime/environment/filters land.

## Amendment 2026-11-13 — JS array-index keys come first

Status of this section: accepted, except the last subsection, which is an
orchestrator call pending the maintainer's confirmation. The Decision above
stays as written, with an inline note on its third bullet. This amendment has
three effects: it corrects one claim in the Decision (JS order is not pure
insertion order), narrows one divergence (plain caller hashes now match JS for
index keys), and supersedes the Decision's third bullet on caller-supplied
ordered hashes (see "Caller-supplied ordered hashes"). Card: k51.

### Correction (fidelity, not a new choice)

The Decision says template dict literals and everything the engine builds are
byte-identical to JS, and the Context describes JS as "insertion order". That
is not what JS does. JS enumerates own keys in the `OrdinaryOwnPropertyKeys`
order: **array-index keys** (canonical numeric strings of the integers
0 … 2^32−2) first, in ascending numeric order, then every other string key in
insertion order. Pure insertion order, which is what the Decision's text
implies, is therefore not 1:1. The oracle shows it:

- `{% for k, v in {"b":1, "2":2, "1":3} %}{{k}};{% endfor %}` → `1;2;b;`
- keys `a`, `10`, `9`, `01`, `-1`, `4294967295`, `4294967294`, `1.5` →
  `9;10;4294967294;a;01;-1;4294967295;1.5;` (`01`, `-1`, `4294967295` and
  `1.5` are not array indices, so they keep insertion order after `a`)

The one ordering seam (today Lib `keys`) applies this JS rule to template dict
literals and engine-built dicts. This brings the Decision's "1:1 with JS"
claim for those objects true to the letter. No decision was changed here.

### Decision (maintainer, 2026-11-13, recorded on k51)

Caller-supplied **plain Perl hashes** also put array-index keys first,
numerically ascending, and only then sort the remaining keys by key. So
`{10 => …, 9 => …, b => …}` from a plain Perl hash iterates `9`, `10`, `b`
(not `10`, `9`, `b`, as plain string sorting would give).

This narrows the documented divergence of the Decision's second bullet: a
plain caller hash now differs from JS only in the order of its **non-index**
keys (sorted instead of insertion order, because that information was never
there). Index-key order matches JS.

### Unchanged

- The consumers are those the Decision lists: `for`, `dump`, `list`,
  `dictsort`, `items`/`keys`, plus `urlencode` and the result of `groupby`
  (the groupby result is an engine-built object, so it follows the JS rule).
- Hash::Ordered is still the engine's representation and still a runtime
  dependency.

### Caller-supplied ordered hashes (orchestrator call, 2026-11-13, k51)

This is an **orchestrator call, not a maintainer decision**, pending the
maintainer's confirmation.

**`Hash::Ordered`.** A caller-supplied `Hash::Ordered` follows the JS rule over
its own insertion order: array-index keys first, numerically ascending, then
the remaining keys in the order the caller gave. Reason: the ordering seam
(Lib `keys`) cannot tell a caller's `Hash::Ordered` from an engine-built one,
because both are the same class. A JS object built in the caller's insertion
order enumerates its index keys the same way, so the JS rule is the 1:1
reading. The alternative, a subclass that marks engine-built dicts so the
caller's order is kept verbatim, would be a new divergence from JS.

**`Tie::IxHash`: known gap.** The Decision says tied hashes are "honoured in
their own order", but the port never implemented tie detection. A
`Tie::IxHash`-tied hash goes through the plain-hash branch today: array-index
keys first, the rest sorted by key. It is tracked on k78 (see the
`Tie::IxHash` card).
