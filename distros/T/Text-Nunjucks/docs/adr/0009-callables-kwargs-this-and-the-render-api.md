# ADR 0009 — Callables: kwargs sentinel, this-binding, registration, and the render API

- Status: accepted
- Date: 2026-09-22
- Tags: semantics, runtime, api, decision, k8

## Context

Measured against upstream (v3.2.4 source + oracle):

- `callWrap(obj, name, context, args)` does `obj.apply(context, args)`: a bare
  symbol call binds `this` to the Context; a member call binds `this` to the
  owner (memberLookup's closure), pinned by the compiler suite
  (`{{ foo.bar() }}` returns `this.baz`).
- Keyword arguments travel as a **trailing plain object tagged
  `__keywords: true`** (`makeKeywordArgs`/`isKeywordArgs`/`numArgs`) — one
  mechanism for funcalls, filters, macros and extensions.
- Macros and `caller()` build on the same `makeMacro` path (positional↔keyword
  remapping, defaults); `{% call %}` is a funcall with a trailing `caller`
  kwarg.
- Async filters take a trailing callback and call `cb(err, res)`; sync filters
  are called `func.call(context, args)` — `this` = Context, no callback.
- `render`/`renderString`/`Template.render` take an optional callback: with no
  cb they return the string and throw on error; with a cb they never throw and
  call `cb(err, res)` (ADR 0003 keeps this CPS shape). `suppressLookupErrors`
  does **not** exist in v3.2.4 — do not port it.
- Error text to preserve: `Unable to call \`x\`, which is undefined or falsey`.

## Decision

- **Keyword arguments** are a trailing hashref carrying a sentinel marker (a
  blessed `Text::Nunjucks::Runtime::KwArgs`, the Perl equivalent of the
  `__keywords` tag), produced and detected in one place. Consistent with the
  `None` sentinel of ADR 0006.
- **`this`-binding**: a Perl object method reached by member call is invoked as
  `$obj->method(@args)` — natural `$self` = the owner. A bare coderef in the
  context is invoked `$code->(@args)` with **no** `this`; the JS "Context as
  `this`" for bare calls is engine-internal plumbing for the macro/`caller`
  machinery (which the compiler wires through frames, not through `this`), not a
  user-facing contract — a documented divergence for user coderefs.
- **Registration** is through `Environment` methods: `add_filter($name, $code,
  $async?)`, `add_test`, `add_global`, `add_extension`. A sync filter receives
  `(@args)`; an async filter receives a trailing callback and calls
  `$cb->($err, $res)`.
- **Public API** (ADR 0003): `render($name, \%ctx, $cb?)` and
  `render_string($src, \%ctx, $opts?, $cb?)` — with no `$cb` they return the
  string and `die` (croak) on error; with `$cb` they never die and call
  `$cb->($err, $res)`. Deferred (async) work resolves the callback; a plain
  `render` that deferred with no callback fails loud (ADR 0003).
- Missing/falsey callable → the exact upstream error text.

Detail of `makeMacro`/`caller`/kwarg-remapping is implemented across Runtime
(k14), Compiler (k15) and Environment (k16); this ADR fixes the shapes they
share.

## Consequences

- One kwargs representation everywhere (funcalls, filters, macros, extensions).
- Custom filters/tests/globals/extensions are ordinary Perl coderefs/objects
  registered on the Environment; async ones opt in via a callback.
- The sync-return-plus-throw / callback duality matches upstream exactly.
- Corpus (render mode) and ported upstream suites (k18, k21) pin the behaviour
  once the runtime/environment land.
