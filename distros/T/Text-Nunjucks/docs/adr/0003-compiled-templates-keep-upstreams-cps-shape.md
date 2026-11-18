# ADR 0003 — Compiled templates keep upstream's callback (CPS) shape

- Status: accepted
- Date: 2026-09-22
- Tags: compiler, async, structure

## Context

Upstream compiles a template to `function root(env, context, frame, runtime,
cb)`. Output and errors leave through `cb`; `asyncEach`, `asyncAll`, `ifAsync`
and async filters are nested callbacks. Perl has no event loop in core, so a
port could drop all of that and compile to functions that simply return a
string.

## Decision

Keep the shape. The Perl compiler emits `sub root ( $env, $context, $frame,
$runtime, $cb )` and the same callback nesting as `compiler.js`. A callback is
invoked synchronously unless user code (an async filter, an extension) defers
it.

Since ADR 0021 the nesting is the same but the text is not literally upstream's:
every continuation but the callbacks of a block call and of `super()` is wrapped in
`$runtime->_continuation($context, sub { ... })`,
the first statement of a root or block sub is a `_render_scope` call, and
imports, macros and includes carry a few port-only statements. ADR 0021 lists
them, and none changes output or error text.

## Consequences

- `compiler.js` can be ported method by method and reviewed side by side; a
  return-value design would be a rewrite, not a port.
- Async filters, async tags and the callback form of `render` exist and behave
  as upstream. An event-loop binding (Future / IO::Async) can be layered on
  later without touching the compiler.
- A plain `render` without callback must still return the string: it works
  because sync callbacks have fired by the time the root call returns — and it
  must fail loud if a template deferred and no callback was given.
- Deep callback nesting costs Perl stack depth. Sequential includes and imports,
  `asyncEach` items, the levels of a template that includes itself, the scope
  walk (`Frame` lookup and resolve over 100 or more frames) and a macro that
  calls itself each nest one call, as upstream nests one JavaScript call.
  - **No depth limit in the port.** Perl sets none; memory does. An `asyncEach`
    over 100,000 items renders (15.7 s, 283 MB, measured on k83, 2026-11-13).
    Upstream stops with a `RangeError` much earlier: on v3.2.4 under node
    v24.19.0, a direct `env.render` renders 2,000 `asyncEach` items and throws at
    2,500, renders 300 sequential includes and throws at 350, and renders 2,500
    self-calls of a macro and throws at 3,000 (through the oracle the thresholds
    shift: 3,000 to 4,000, 400 to 500 and 2,000 to 2,500). It is a few thousand
    items or self-calls and a few hundred sequential includes, depending on the
    node version and the call path. (The 10,000 first noted on k83 was a probe
    point that threw, not the threshold.) That is a difference: where upstream
    throws, the port renders. Whether the port should emulate the JS engine's
    limits (heap cap, maximum string length, call-stack depth) is not decided
    (k69, which recommends not emulating them).
  - **The "Deep recursion" warning is noise for a bounded nesting.** Perl warns
    at 100 nested calls. The CPS helpers, the scope walk and the macro call
    switch the `recursion` warning category off at the call sites that nest per
    step or per level (k83), pinned by `t/10-deep-recursion.t`.
  - **An endless recursion gets no early warning.** A template such as
    `{% macro f(n) %}{{ f(n+1) }}{% endmacro %}{{ f(0) }}` used to warn twice and
    then die with "Out of memory". Now it dies with "Out of memory" and no
    warning, where upstream throws a catchable
    `RangeError: Maximum call stack size exceeded` at about 2,500 levels. The
    port runs until memory is exhausted. Silencing the warning for a template's
    own recursion (a self-calling macro) was the main agent's choice, not the
    maintainer's, and goes to the maintainer together with k69.
