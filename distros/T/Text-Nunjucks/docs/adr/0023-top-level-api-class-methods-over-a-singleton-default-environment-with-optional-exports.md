# ADR 0023 — The top-level API: class methods over a singleton default Environment, optional exports

- Status: accepted
- Date: 2026-11-17
- Tags: api, decision, k101, k20

## Context

**What upstream does.** `index.js` of Nunjucks v3.2.4 is a module object. It
keeps one module-level variable, `let e`, the default Environment.
`configure(templatesPath, opts)` builds a `FileSystemLoader` (or a `WebLoader`
in a browser build), constructs `new Environment(loader, opts)`, stores it in
`e`, calls `e.express(opts.express)` when that option is truthy, and returns it.
`reset()` sets `e` back to `undefined`. `compile`, `render` and `renderString`
call `configure()` first when `e` is unset, then delegate: `render` and
`renderString` to the Environment's methods of the same name, `compile` to
`new Template(src, env, path, eagerCompile)`. `renderString` has three
arguments, `(src, ctx, cb)`, and passes them on to `e.renderString(src, ctx,
cb)`. The module also re-exports its components as properties: `Environment`,
`Template`, `Loader`, `FileSystemLoader`, `NodeResolveLoader`,
`PrecompiledLoader`, `WebLoader`, `compiler`, `parser`, `lexer`, `runtime`,
`lib`, `nodes`, `installJinjaCompat`, `precompile` and `precompileString`.
`index.js` requires all of them, so requiring `nunjucks` loads the whole engine.

**What the Environment method does.** ADR 0009 fixes the Environment's render
API as `render($name, \%ctx, $cb?)` and `render_string($src, \%ctx, $opts?,
$cb?)`. Upstream's `Environment#renderString(src, ctx, opts, cb)`
(`environment.js:321`) starts with `if (lib.isFunction(opts)) { cb = opts; opts
= {}; }`, and the port's `Text::Nunjucks::Environment::render_string` does the
same through `Lib->is_function`. A coderef in the options slot is therefore the
callback.

**The house rules.** Skill `getty-perl-core` says: "No package-level state but
true constants (an `%ENGINE_CLASS` table counts); a per-process cache is an
attribute on the singleton ... not `my %CACHE`." It also says "Bare subs only
in non-class utility modules imported as functions" and "never rely on default
exports". Skill `getty-perl-moo` names the singleton idiom: `->instance` on a
`MooX::Singleton` class, never `->new`. Upstream's `let e` is package-level
state, so a literal port of the module object would break the first rule.

**The port today.** `lib/Text/Nunjucks.pm` is the distribution's front page and
loads nothing: `use Text::Nunjucks;` alone gives no working engine, and the
SYNOPSIS loads `Text::Nunjucks::Environment` itself. No module in the
distribution uses Exporter. Neither ADR 0009 nor any other ADR, nor the core
skill, fixes a Perl shape for the top-level API; that is what k101 asked.

## Decision

Taken by the maintainer on 2026-11-17. The main agent's recommendation on k101
had been option B (no Exporter, components by module name, `render_string` with
upstream's three arguments); the maintainer chose D, and chose the options
form of `render_string` and loading by module name as described below.

1. **Class methods over a singleton, plus optional functions (option D).**
   `Text::Nunjucks` offers `configure`, `reset`, `compile`, `render` and
   `render_string` as class methods. They work on a singleton attribute that
   holds the default Environment, not on a package variable; this is the house
   rule's "per-process cache is an attribute on a singleton". As upstream,
   `compile`, `render` and `render_string` configure a default Environment
   with no arguments when none exists, and `reset` drops it. In addition
   `Text::Nunjucks` has an optional import list: the same five names are
   exportable as plain functions, through Exporter with `@EXPORT_OK` only and
   never a default export. `use Text::Nunjucks;` imports nothing. How an
   imported function reaches the class method is left to the implementation;
   the decision is that both call forms reach the same default Environment, so
   `configure` through one form is seen by `render` through the other.

       use Text::Nunjucks;
       Text::Nunjucks->configure( 'views', { autoescape => 1 } );
       print Text::Nunjucks->render( 'page.html', { title => 'x' } );

       use Text::Nunjucks qw( configure render_string );
       configure( 'views', { autoescape => 1 } );
       print render_string( '{{ a }}', { a => 1 } );

2. **`render_string` takes options like the Environment method.** The top-level
   `render_string` is `render_string($src, \%ctx, $opts?, $cb?)`, the shape of
   ADR 0009, where upstream's `index.js` has `renderString(src, ctx, cb)` with
   three arguments. This is a deliberate difference. It costs index.js's call
   form nothing: the default Environment's `render_string` takes a coderef in
   the options slot as the callback (see Context), so
   `render_string($src, \%ctx, $cb)` keeps working unchanged. The difference
   is only that the options, notably `path`, are reachable at the top level
   too.

3. **`use Text::Nunjucks` loads every component `index.js` requires** that
   exists in the port: Environment, Template, Loader, the loaders that exist
   (`Loader::FileSystem` and `Loader::Precompiled`), Lib, Compiler, Parser,
   Lexer, Runtime and Nodes. Not loaded because they do not exist: precompile
   (k23) and jinja-compat (k22). Not loaded because they are out of scope:
   `NodeResolveLoader` and `WebLoader` (ADR 0018) and the express module (ADR
   0022). Components are reached **by module name**:
   `Text::Nunjucks::Environment->new(...)`. There are **no class-name
   accessors** such as `Text::Nunjucks->Environment` or `->FileSystemLoader`.
   That is a difference from `nunjucks.Environment` and its siblings, and it
   is recorded here.

4. **Left with their cards.** `install_jinja_compat` stays with k22,
   `precompile` and `precompile_string` with k23, and neither is decided here.
   For `configure`'s `express` option, ADR 0022 puts express out of scope and
   `Text::Nunjucks::Environment` has no `express` method, so upstream's
   `e.express(opts.express)` has no counterpart. What `configure` does with a
   truthy `express` is not decided by this ADR; see Consequences.

## Options not taken

- **(A)** Plain functions `Text::Nunjucks::render(...)` over a package-level
  default Environment: needs an ADR exception to the house rule on package
  state.
- **(B)** Class methods only, over a singleton attribute, no import list: the
  main agent's recommendation, with upstream's three-argument `render_string`.
  D is B plus the import list.
- **(C)** Object style only: `Text::Nunjucks->configure` returns an
  Environment and the global API, which upstream's `api.md` calls discouraged,
  is not offered. A recorded divergence; not taken.

## Consequences

- k20 can port `configure`, `reset`, `compile`, `render` and `render_string`,
  and make `use Text::Nunjucks` load the components of point 3. Its POD then
  documents both call forms; the SYNOPSIS need no longer load
  `Text::Nunjucks::Environment` itself.
- Once k20 lands, "DIFFERENCES FROM NUNJUCKS" lists: the top-level
  `render_string` takes options (point 2); no class-name accessors for the
  components (point 3); the default Environment lives in a singleton, not in a
  module variable, and `configure`, `reset` and the rest are class methods or
  optionally imported functions rather than properties of a module object
  (point 1).
- Tension with the house rules, noted for the implementation: the "bare subs
  only in non-class utility modules" rule meets exported functions in a class
  module. The exported functions are thin entry points that delegate to the
  class methods and hold no logic or state of their own; the maintainer
  accepted D with that shape.
- Open question for the worker on k20, not decided here: what `configure` does
  with a truthy `express` option. Upstream calls `e.express(...)`, which the
  port does not have (ADR 0022). Candidates are to ignore it, to die with a
  message, or to follow whatever k24 / ADR 0022 say; any of these must be
  recorded, and it needs the maintainer if ADR 0022 does not already settle
  it.
- Also for k20: `configure` builds the loader itself as upstream does (a
  `FileSystemLoader` from the path, with `watch` and `noCache` from the
  options); how `watch` behaves is ADR 0018's.
- Reversible: dropping the import list or the options form changes the public
  API and needs a new decision.
