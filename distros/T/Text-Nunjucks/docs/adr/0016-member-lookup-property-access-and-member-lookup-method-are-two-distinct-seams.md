# ADR 0016 — member_lookup (property access) and member_lookup_method (method call) are two distinct seams

- Status: accepted
- Date: 2026-09-23
- Tags: semantics, runtime, member-lookup, decision, regex, callable
- Replaces: the implicit "member_lookup returns a Coderef for any blessed object" contract relied on by k17-test scaffolding and the k14 runtime; ADR 0009 wording on `this`-binding stays valid (both seams bind `this` the same way once the lookup has produced the callable), the change is which seam the compiler emits and what the seam returns.

## Context

ADR 0008 (native JS methods) and ADR 0009 (callables / `this`-binding) together
fix that `{{ foo.bar() }}` reaches `foo` and invokes `bar` with `this = foo`,
while `{{ foo.baz }}` is a property read. JS makes that distinction implicit —
`obj[key]` is property access; only `()` turns the result into a call.

Perl has no language-level "property vs method" split: `$obj->method` *calls*
the method and returns whatever the method returns. The previous
`Text::Nunjucks::Runtime::member_lookup` papered over the gap with one rule
for every blessed object: "if `can($key)`, return a bound coderef; otherwise
return undef." That kept `{{ obj.greet() }}` working (the coderef was the
argument `call_wrap` then invoked) and matched how the curated String /
Array / Number emulations were already structured (ADR 0008 — `length`,
`toUpperCase`, etc. are coderefs that `call_wrap` invokes).

The k43 regex work exposed the cost of that single rule. ADR 0013 requires the
regex object to expose `test`, `exec`, `source`, `flags`, `global` as members
templates call or read. `test` and `exec` are method-shaped: `{{ r/.../i.test(s) }}`
must invoke them. `source`, `flags`, `global` are property-shaped: `{{ r.flags }}`
must render the string, `{{ r.global }}` must render `true`/`false`. With the
single-rule member_lookup, a property-shaped access on a blessed object returns
a coderef, which then renders as `[object Object]` (or the stringified coderef)
instead of the underlying value — and that is observable to templates.

There are three places the gap could be closed:

- **Heuristic in member_lookup.** Call the method, inspect the return value, wrap
  if it is a coderef, return otherwise. Breaks the existing
  `{{ obj.greet() }}` shape (member_lookup now returns "hi world" instead of a
  coderef, so `call_wrap` rejects it as "not a function") and punts the
  decision to runtime — every blessed-object access pays a coderef-test.
- **Single function, context flag** (`member_lookup($obj, $key, $as_method = 0)`).
  Equivalent in effect to the two-function shape but keeps one name; the
  default is non-obvious and the flag is easy to get wrong at the call site.
- **Two seams, compiler picks.** `member_lookup` does property access (returns
  the value); `member_lookup_method` returns a bound coderef. The compiler
  emits `member_lookup_method` at FunCall sites whose name is a LookupVal on a
  blessed object (or any object whose method lookup must come back as a
  callable), and `member_lookup` everywhere else. Mirrors JS: property access
  vs. invocation are distinct AST shapes there too.

The third option is the only one that keeps the runtime's surface declarative
(no runtime heuristic), keeps the compiled template readable
("property read" vs. "method bind" are spelled in the symbol name), and
matches what upstream does (Nunjucks itself never had to make this choice
because JS has the language-level distinction).

## Decision

- **Property access: `Runtime::member_lookup($obj, $key)`.** Returns the value
  of the member as the template sees it. For blessed objects, this calls the
  accessor (or reads the Moo attribute) and returns the value. For arrays,
  hashes, SafeStrings, numbers, strings (per the ADR 0008 emulated surface) —
  same semantics as before, except blessed-object cases now return a value
  rather than a coderef.
- **Method call: `Runtime::member_lookup_method($obj, $key)`.** Returns a bound
  coderef that, when invoked, runs the underlying method with `this = $obj`.
  For blessed objects, the coderef is `sub { $obj->$key(@_) }`. For the curated
  String/Array/Number/SafeString emulations, the coderef is the existing
  function (ADR 0008) bound to the owner.
- **`call_wrap` is unchanged.** It receives a coderef (always — that's what
  FunCall produces via `member_lookup_method`) and invokes it.
- **Compiler**: `compile_fun_call` emits `$runtime->member_lookup_method(...)`
  for its callable argument, not `$runtime->member_lookup(...)`. All other
  callers of `member_lookup` (the LookupVal path in `compile_lookup_val`,
  internal callers in `member_lookup`/`keys`/etc.) stay on the value-returning
  seam.
- **Hash/array indexing and SafeString indexing** keep their existing
  `member_lookup` behaviour (return the value); no new code path.
- **Reconciliation with the existing `t/10-runtime.t` "method member -> a bound
  closure" subtest**: that subtest is updated to call the new seam
  (`member_lookup_method`) so it still pins the contract; the new property-read
  shape is pinned by a fresh subtest on `member_lookup`.

## Consequences

- `{{ r.flags }}` and `{{ r.global }}` render the right values; `{{ r.test(s) }}`
  still works. Regex literals (ADR 0013) are usable from templates without a
  workaround.
- Templates calling user-defined methods on blessed Perl objects
  (`{{ obj.greet() }}`, the k17-test scaffolding pattern) keep working —
  `compile_fun_call` now resolves through `member_lookup_method`, which still
  binds `this = obj` and still produces a coderef for `call_wrap` to invoke.
- `member_lookup` is now the canonical "give me the value" seam for any
  property-shaped read; future emulated surfaces (e.g. jinja-compat
  `object.attr` reads, ADR k22) plug into the same seam without the
  Coderef-vs-Value ambiguity.
- The k43 worker had a half-finished `member_lookup` rewrite that combined
  property-read and method-bind in one heuristic; that rewrite is discarded.
  k43 lands the Regex class, `make_regex`, and the two-seam `member_lookup` /
  `member_lookup_method` split in one change, with the compiler updated to
  match.
- One new test subtest in `t/10-runtime.t` pins the property-read contract;
  the existing "method member -> a bound closure" subtest moves to the
  `member_lookup_method` API.
- ADR 0009 wording on `this`-binding stays correct for both seams; ADR 0008
  emulations are reachable through `member_lookup_method` for method-shaped
  members and through `member_lookup` for property-shaped members
  (`length`), with no change to the curated list.