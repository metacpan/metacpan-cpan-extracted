# ADR 0021 — A Context lives as long as what is still going to run in it

- Status: accepted
- Date: 2026-11-17
- Tags: memory, compiler, runtime, environment, gc, decision, k108

## Context

Upstream's compiled code is a tree of closures over `context` and `frame`, and
the Context holds the macros (`context.setVariable`, `context.addExport`).
That is a cycle, and a tracing GC collects it. Perl's reference counting never
does. Before this ADR a render kept its Context, and with it the caller's
context data, when its template made a macro that read an outer name, a
`caller()` block, or a macro caught in one of the cycles B to D below (a macro
that only used its own arguments and was not stored, nor made after or around
an async construct, left nothing behind): 4.5 kB per render for
`{% macro m() %}{{ x }}{% endmacro %}{{ m() }}`, about 728 kB per render with a
2000-row context. The pre-release audit found it (k108). There turned out to be
four cycles, not one:

- **A. Context <-> macro.** A macro that reads an outer name (a variable,
  another macro, a global, itself) captures `$context`; the Context holds the
  macro.
- **B. Frame <-> macro.** Every macro captures `$frame`, because it swaps and
  restores that variable on each call (upstream: `frame = callerFrame`). A
  macro stored in a frame that the variable reaches (`{% set f = m %}`, an
  import `with context` inside a `for`, the `caller` of a macro call that died
  before it restored the variable) is a cycle with no outer-name read at all.
- **C. A macro that contains an async construct captures `$cb`.** For a block
  sub that is the root continuation, for a library the callback of
  `getExported`; both name a Context.
- **D. A Perl closure keeps its enclosing closure instance alive.** A macro
  defined after an `import`, `include`, `extends`, `super()` or async filter in
  the same root or block sub is created inside that construct's continuation,
  so it holds everything the continuation captured, `$context` included, even
  if it reads nothing.

Weakening only the macro's hold on its Context does not fix C and D, and a plain
`weaken` of the Context in a macro breaks a library: the macros of an imported
template call each other and read the library's variables through its Context,
which has to outlive the library's render.

## Decision

**The mapping.** JS tracing GC becomes Perl reference counting under one rule:
**a Context is held by what is still going to run in it.** That is

1. the call that started the render, while it is on the stack
   (`Template->render`, `_get_exported`);
2. each continuation (any callback the compiled code hands out to be called
   when something is done), from the moment it is handed out until it is called;
3. the importing Context, for the Context of a library it imported, one that
   failed as well as one that succeeded;
4. the including Context, for an included Context that made a closure (below);
5. the hash and the function wrappers that public `Template->get_exported`
   returns.

No root or block sub, and so no macro or continuation made inside it, holds its
Context otherwise. When a Context is freed it puts an empty Frame into every
`$frame` variable and a stand-in that dies with a clear error into every
`$context` variable that the code of its render can still see (Context
`DEMOLISH`).

**Why `undef $frame` at the end of a sub was rejected**, the first prototype
for cycle B: a continuation the application deferred (an async filter) reads
`$frame` after the sub delivered its result, without assigning it first; error
paths (`if (t_err) { cb(t_err); return; }`) never reach a finish point; and
macros of one template keep sharing the one frame variable after its root sub
returned (the oracle shows it: an imported macro whose call block is run by a
sibling sees the sibling's arguments), so the variable cannot become per call.
Resetting the variable when the Context dies is the one moment nothing of that
render can run with its Context any more.

**Emitted code.** Each line is listed because it differs from `compiler.js`,
and each is unobservable in a template: it runs bookkeeping on the Context or
changes who holds what, and changes neither output nor error text.

| Emitted | Where | What it does |
|---|---|---|
| `$runtime->_render_scope(\$context, \$frame);` | first statement of every root and block sub | weakens the sub's `$context` variable, registers both variables with the Context |
| `$runtime->_continuation($context, sub {` ... `}))` | every continuation except the callbacks of a block call and of `super()` (`_make_callback`, the include's waterfall callback) | the wrapper holds the Context until the continuation is called; the extra `)` is the only textual difference from upstream's `})` |
| plain `sub {` ... `})` | the callback of a block call and of `super()` | the block's own pending continuations hold the Context; a hold of its own would be kept for good by a macro of the block that captures this `$cb` and sits in the block's frame |
| `->_get_exported(` plus `$context->_keep_alive($_[2]);` | `import`, `from ... import`: the statement is first in the callback's error branch, `if($t_3) { $context->_keep_alive($_[2]); $cb->($t_3); return; }`, and again after the error check | calls upstream's `getExported` (third callback argument: the library's Context, on success and on a render error) and makes the importing Context keep it |
| `$context->_made_closure;` | before each `make_macro` and before a `CallExtension` with content arguments | tells the Context that something that can outlive the render exists |
| `, $context)` as the fourth argument of the include's `render` | `include` | tells the included Context who included it |
| `undef $callback;` | in the error branch of the include's `render` callback | see "The include rule" |

The statements in front of `$cb->($t_err)` in an error branch (`undef $callback;`
at the include, `_keep_alive` at the imports) are the `$on_error` argument of
`_make_callback`.

Closers are `})` for a plain `sub {` and `}))` for a `_continuation(` call, and
they now come in the reverse order of opening, so the newest goes in front.
`_add_scope_level` and `_make_callback` take a `$plain` flag for that. This is
also why ADR 0003's "the same callback nesting as `compiler.js`" no longer
holds to the letter; the nesting is the same, the call that wraps a
continuation (all but the block and `super()` callbacks) is not. Precompiled root subs (k23) must emit the same lines.

**The port-only surface.** All of it is private, with an underscore name or an
internal argument, and has no POD, except `Text::Nunjucks::Context::Gone` (a
class with a short engine-internal POD, no public methods) and the
`get_exported` / `render` passages of `Text::Nunjucks::Template`'s POD, which say
what a Perl caller sees.

- Compiler::Compiler: `_continuation_open`, `_emit_keep_alive`,
  `_keep_alive_statement`, `_emit_made_closure`; the `$plain` parameter of
  `_add_scope_level` and `_make_callback`, and `$on_error`, the third argument
  of `_make_callback` after `$res` and `$plain`, used at the include and at both
  import sites.
- Runtime: `_render_scope`, `_continuation`.
- Context: `_keep_alive`, `_included_by`, `_made_closure`, `_delivered`,
  `_hand_over`, `_track_scope`, `_track_var`, `DEMOLISH`, the accessors
  `_frame_class` and `_gone_class`, and the attributes `_kept`, `_includer`,
  `_has_closure`, `_has_delivered`, `_context_vars`, `_frame_vars`.
- Template: the fourth positional argument of `render` (the including
  Context), `_get_exported`, `_hold_context`, the file-level FieldHash
  `%context_of`, `_gone_class`.
- `Text::Nunjucks::Context::Gone`, the stand-in, one process-wide object
  without state, like `Runtime::None`. Its methods `_made_closure`,
  `add_export`, `set_variable` and `_keep_alive` do nothing: they are pure
  writes into a Context nobody can read, and a kept macro that defines a nested
  macro or imports a library in its body then works. Every other method call
  dies with `template code ran after its render had ended: its Context is gone
  (METHOD)`, a `Lib::Error`; the text is port-only. Everything that reads a
  Context (`lookup`, `get_variables`, `get_exported`, `get_block`,
  `get_super`) goes through the object, so no read gets past it.

**`getExported` is split.** `_get_exported` is upstream's `getExported`, plus
the Context as a third callback argument, on success and on a render error
(on a compile error no Context exists, and the callback gets one argument).
Public `get_exported` is a port-only wrapper around it for Perl callers: it
strips the Context from an error and gives its callback `($err, $exported)`
on a render error and on success, and `($err)` on a compile error. On success it
makes the Context live as long as the returned hash (Hash::Util::FieldHash
keyed on the hash) or as long as any function that was a value of that hash.
Every top-level function in the hash is wrapped, so one extracted from the hash
holds the Context; the same function under two names gets one wrapper. The
wrapped functions include a coderef of the application that the library
re-exports (`{% set g = f %}`): it comes back as the wrapper, so its identity is
not the one the application passed in (HEAD: the same reference). A function
nested in an exported array or dict is held only through the hash. Argument
counts are upstream's: the callback gets one argument on a compile error and two
on a render error. A library that failed is therefore not kept for a Perl
caller, which falls under limitation (a).

**The include rule.** An included template renders in a Context of its own, and
upstream keeps it reachable through whatever the included template handed out: a
macro or call block it put into an array of the includer, a function of the
application it passed one to, an extension that kept the body it was given. So
an included Context holds its includer from creation, and **the includer takes
it over (`_keep_alive`) when the included render has delivered and has made a
closure, whichever comes last**: a macro, a call block, an extension body, or
it keeps another Context (an import, a nested include). A plain partial is not
kept.

- *Why not at the moment the closure is made.* Until the included render
  delivers, the include's continuation holds the including Context, and a macro
  of the included template that contains an async construct holds that
  continuation as its `$cb`. An included render that never completes would keep
  both for good.
- *Why not only at delivery.* An `include` inside `if` or `for` whose template
  waits for an async filter delivers after the includer went on, and its first
  macro may come later.
- *Why not always keep.* A partial included in a loop of 100,000 rows would hold
  100,000 Contexts until the render ends, plain partials included.
- *Errors.* A render that delivers an error is taken over like any other. In the
  error branch the include's callback does `undef $callback;` before it calls
  `$cb`: the waterfall's last continuation, the rest of the including template,
  is never called after an error and would hold the includer through the
  included template's macro, which closes a cycle. Once the callback has seen an
  error it never needs the waterfall step again, because `Template->render`
  drops every result that comes after an error.

**The import rule.** A library that fails is kept by the importing Context like
one that succeeded, in both branches of the callback's error check. Upstream
goes on after a failed import with what follows the `if`, the `for`, the macro
call or the `set` capture the import stands in, and that code may call a macro
the library handed out (into an array of the importing template, to a function
of the application) before it failed; if the importing Context did not keep the
library's, that call would find its Context gone where upstream renders.

- *Price.* A failing import inside `asyncEach` / `asyncAll` leaks again, each
  shape exactly as much as before this ADR: 684 of 3040 shapes of the
  import-site matrix (k121).
- *Rejected after measuring.* Dropping the import callback after the library's
  first error brings the import-site leaks to 0, but 600 double-answer shapes
  then differ from upstream: 220 error-then-success shapes where the tail no
  longer runs, and 380 error-error shapes where the render callback is not
  called a second time.

## Who decided what

- **Maintainer (2026-11-17):** fix the leak with a weak-capture direction;
  accept limitation (a) below; close the direct `get_exported` edge (the
  returned macros keep their Context alive); template-visible behaviour stays
  1:1.
- **Main agent's choices:** an including Context keeps an included one only when
  that render made a closure (option B, not "always keep"); the Context is also
  held through the hash that public `get_exported` returns; a library that fails
  is kept by the importing Context like one that succeeded, the same decision as
  for include, not one the maintainer took.
- **Worker's choices:** the mechanism. Weak capture for all compiled code and
  not only for macros, the continuation wrapper, `Context::Gone` and its error
  text, resetting frame variables when a Context dies, `undef $callback;` on the
  include's error path in place of "no take-over on error".
- **Maintainer (2026-11-17), accepting the recommendation of the main agent and
  the fidelity-auditor:** limitations D2 and D3 below, and the sub-shape under
  "Still leaking" that this ADR introduces, to be fixed under k121.

## Consequences

**Limitations.** Each is a documented divergence or a cost, and is in
"DIFFERENCES FROM NUNJUCKS" and LIMITATIONS of `Text::Nunjucks` unless said
otherwise.

- **(a) Kept template code after its render.** The maintainer accepted this
  for a macro that the application's own Perl code keeps and calls after the
  render that defined it has ended, when it reads outer names. The worker and
  the main agent widened the same rule to call blocks and extension bodies,
  and the maintainer has not ruled on that. Such code dies at its first read of the Context with
  `template code ran after its render had ended: its Context is gone (METHOD)`.
  One that reads only its own arguments and locals works, defining nested
  macros in it works, and an import in its body works while the body runs
  synchronously. Upstream's macro keeps its Context for as long as the macro
  lives.
- **D2 (accepted by the maintainer, 2026-11-17).** An async filter or extension that calls its
  callback a second time dies in the application's event loop in three cases,
  each with its own consequence:
  - The result was already delivered, and what follows reads a variable: it
    dies with the Context-gone error where upstream calls the render callback
    again.
  - The included template made no closure, the including render is still
    pending, and what follows reads a variable: the same.
  - The first answer was an error and the importing render had ended before the
    second answer came: it dies at `get_exported`, where upstream runs the rest
    of the importing template.

  HEAD and the tree both already differ from upstream on a second callback
  through the include waterfall (k119).
- **D3 (accepted by the maintainer, 2026-11-17).** Every executed import keeps the library's
  Context until the importing render ends. A from-import in a loop of 20,000
  peaks at +122 MB, about 6 kB each (HEAD: +2.4 MB); the memory is freed when
  the render ends. No cheaper way was found: tying the library's Context to the
  frame would break a macro assigned to an outer variable with `set`.
- **Kept included Contexts.** Until the including render ends, per include and
  with 12 context variables: about 8.0 kB with a macro, 2.8 kB with a call
  block only, 9.1 kB with a from-import, 0.08 kB for a plain partial (as HEAD).
  The figure grows with the number of context variables. HEAD kept the macro
  case for good.
- **Still leaking (k121), and in one sub-shape more than before this ADR.**
  - An included template that makes a closure reaching its callback and then
    fails inside an `asyncEach` / `asyncAll` body after a deferral leaves
    Contexts behind; a plain `for` with an async filter counts as such a loop.
    For a macro that reads an outer name this is no worse than before this ADR.
    For an argument-only macro it is a leak this ADR introduces. Minimal case:
    `main.njk` is `{% for r in [1,2] %}{{ y | later }}{% include "i.njk" %}{% endfor %}`
    and `i.njk` is `{% macro m(a) %}[{{ a | later }}]{% endmacro %}{% include "missing.njk" %}`.
    At 04e3a23 it left 0 Contexts and 0 Frames; the tree leaves 2 Contexts and
    3 Frames. The same holds in `asyncEach` after a deferral and in `asyncAll`
    with a deferring sibling. On the auditor's matrix with every outer read
    removed from the macro bodies, 42 include-site shapes leak more than before
    (28 of them from nothing), no import-site shape does, and 3282 shapes leak
    less. It is the price of the include rule plus the take-over on error, on
    the error path only. The maintainer accepted this on 2026-11-17; k121 tracks the fix.
  - An included template that hands a macro containing an async construct to
    the includer and then never completes does the same.
  - A failing import inside `asyncEach`, `asyncAll` or a plain `for` with an
    async filter after a deferral (see the import rule).
- **The `get_exported` corners.** A copy of the returned hash holds the Context
  only if it holds a top-level function (every one of those is a wrapper); a
  function nested in an array or dict and taken out of it after the hash and all
  top-level functions are gone finds the Context gone; a returned hash stored
  back into data the Context holds leaks one Context, as before.

**Cost.** Executed Perl statements per render, HEAD to this tree (fidelity
audit): plain +0.4%, macro +0.5%, import +1.2%, mixed +2.1%, extends +3.0%,
include in a loop +11.1%, include with a from-import in a loop +20.4%. Wall
time was not usable as a measure on the audit machine.

**Verified.** Revert-checked: at HEAD's `lib/`, the freed-Context assertions of
`t/10-leaks.t` and `t/10-macro-lifetime.t` fail. Against real upstream with a
queued async filter, a matrix of 1,616 include shapes renders like upstream and
leaves no Context or Frame alive, and randomized interleaved renders give the
same output as HEAD with no Context left (HEAD: hundreds).

## Alternatives considered

- **A strong cycle, broken explicitly when the render ends.** Has no trigger for
  a direct `get_exported`, and an escaped macro then renders silently wrong
  instead of failing.
- **The render holds its Context until the root callback fires.** Considered
  and not chosen; this ADR's rule holds the Context through the call and the
  pending continuations instead, which is the same hold for a render that
  completes and none for one that is abandoned.
- **Always keep included Contexts (option C).** One Context per include for the
  whole render, plain partials included. The only measured difference from B is
  inside D2.
- **No take-over when the included render delivers an error.** Diverges from
  upstream in synchronous templates: what follows an `if`, a `for`, a macro call
  or a `set` capture around a failing include still runs, calls a macro the
  included template had handed out, and finds its Context gone (14 of 18
  measured lines differed, 10 of them in purely synchronous templates).
  `undef $callback;` closes the same cycle without that.
- **`undef $frame` where a sub finishes.** See the Decision.

## Open items

- k80: `_hold_context` and the FieldHash key walk a plain hash; they follow when
  the import namespace becomes an ordered hash.
- k23: precompiled root subs must emit the same lines as above.
- k102: the extension surface; `_made_closure` before a content argument is the
  only hook so far.
- k119: a second callback through the include waterfall.
- k121: the leaks named above.
- k118 (asyncEach / asyncAll with four or more loop names) and k96 (the
  Environment with a caching loader is never freed) are leaks this ADR does not
  touch; they stay open.
