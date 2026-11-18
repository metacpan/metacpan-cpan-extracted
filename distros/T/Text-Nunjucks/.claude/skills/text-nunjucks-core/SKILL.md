---
name: text-nunjucks-core
description: "Use on any work in the Text::Nunjucks distribution — porting a Nunjucks source file (lexer, parser, nodes, transformer, compiler, runtime, environment, filters, tests, globals, loaders, jinja-compat) to Perl, deciding how a JavaScript semantic maps to Perl, writing or regenerating oracle/corpus tests, or judging whether a behaviour is a bug or a recorded divergence."
---

# Text::Nunjucks — porting contract

Text::Nunjucks is a **1:1 port of Nunjucks `v3.2.4`** (the tag pinned in
`maint/fetch-upstream`). "1:1" is a measurable claim: for the same template,
context and options, the Perl port produces the byte-identical output — and the
same error message — as the original. Jinja2 behaviour, the Nunjucks docs and
what "would be nicer in Perl" are all irrelevant where they disagree with what
upstream *does*.

## The three sources of truth, in order

1. **The oracle** — `node maint/oracle.js` runs cases through the real upstream
   and prints its output. What it prints is correct by definition.
2. **The upstream source** — `upstream/nunjucks/nunjucks/src/*.js` (gitignored;
   `maint/fetch-upstream` restores it). Read the JS before writing the Perl.
3. **The ADRs** in `docs/adr/` — every place the port *knowingly* differs or had
   to choose a mapping. A difference without an ADR is a bug.

The upstream docs (`upstream/nunjucks/docs/`) describe intent and are wrong in
places. Never settle a behaviour question from them; ask the oracle.

**Model memory is wrong about this engine.** Autoescape is *on* by default, a
backslash is escaped, `'0'` and `[]` are truthy, and `null is defined` is true.
Code written from memory passes the obvious tests and fails the port. Probe the
oracle instead — the details are in
[references/js-semantics.md](references/js-semantics.md).

## Port by structure, not by feature

One upstream file is one Perl module; one upstream function is one Perl method
with the same name in `snake_case` (`parseFilterArgs` → `parse_filter_args`,
`_emitLine` → `_emit_line`), in the same order as upstream. Keep upstream's
control flow even where Perl offers something shorter — the port is reviewed by
reading both files side by side, and a "cleverer" Perl body cannot be reviewed
that way. Upstream comments worth keeping come along.

| Upstream `src/` | Perl module |
|---|---|
| `index.js` | `Text::Nunjucks` (`configure`, `render`, `render_string`, `compile`, …) |
| `lib.js` | `Text::Nunjucks::Lib` (incl. `TemplateError`, `escape`) |
| `object.js` | no module — Moo replaces `Obj`/`EmitterObj` (ADR 0002) |
| `lexer.js` | `Text::Nunjucks::Lexer`, `::Lexer::Token`, `::Lexer::Tokenizer` |
| `nodes.js` | `Text::Nunjucks::Nodes` (loads the classes), one file per node type under `::Nodes::` |
| `parser.js` | `Text::Nunjucks::Parser`, `::Parser::Parser` |
| `transformer.js` | `Text::Nunjucks::Transformer` |
| `compiler.js` | `Text::Nunjucks::Compiler`, `::Compiler::Compiler` — emits **Perl** source |
| `runtime.js` | `Text::Nunjucks::Runtime` (`member_lookup`, …), `::Runtime::Frame`, `::Runtime::SafeString`, `::Runtime::None`, `::Runtime::KwArgs`, `::Runtime::Regex` |
| `environment.js` | `Text::Nunjucks::Environment`, `::Context`, `::Template` (one file each) |
| `filters.js` / `tests.js` / `globals.js` | `::Filters` / `::Tests` / `::Globals` |
| `loader.js`, `node-loaders.js`, `precompiled-loader.js` | `::Loader`, `::Loader::FileSystem`, `::Loader::Precompiled` |
| `precompile.js` | `::Precompile` |
| `jinja-compat.js` | `::JinjaCompat` |

Out of scope, by decision: `express-app.js`, `web-loaders.js`,
`precompile-global.js`, the browser bundles, `NodeResolveLoader`, and
`FileSystemLoader`'s chokidar `watch`, which throws upstream's no-chokidar
error (ADR 0018). Do not port them and do not leave stubs.

Names a *template author* sees stay exactly upstream's — filter, test and global
names, tag names, `loop.index0`, option keys (`throwOnUndefined`, `trimBlocks`),
error message text. Only the Perl-facing API is snake_cased.

## Decided mappings (read the ADR before touching the area)

- **Perl 5.40, native value kinds (ADR 0001).** JS distinguishes boolean, number
  and string at runtime; so does the port, with `builtin::is_bool`,
  `builtin::created_as_number`, `builtin::true`/`false`. `{{ 1 == 1 }}` renders
  `true`, `"1" + 1` is `"11"`, `1 + 1` is `2`. Never decide a value's kind with a
  regex (`looks_like_number`) — a numeric *string* is a string. Values decoded
  from JSON may arrive as `JSON::PP::Boolean`; normalise at the boundary.
- **Moo (ADR 0002).** Classes and roles per skill `getty-perl-moo`.
- **One class per file (ADR 0020).** Every class is its own `.pm` at the path
  its name implies (`Lexer::Token` is `Lexer/Token.pm`); no inner `package`
  blocks, no classes generated at run time. AST node types are one hand-written
  file per `extend()` call in `nodes.js`. Class names stay upstream-shaped
  (`Parser::Parser`, `Compiler::Compiler`). Every class loads alone via
  `require`; `xt/one-class-per-file.t` guards it.
- **CPS kept (ADR 0003).** The compiler emits callback-style code exactly like
  upstream: `sub root ( $env, $context, $frame, $runtime, $cb )`, errors through
  `$cb->($err)`, async tags and async filters as nested callbacks. Callbacks run
  synchronously unless user code defers them. Do not "simplify" to return values.
- **Upstream pin + oracle (ADR 0004).** Bumping the tag is a porting decision.

## Undecided mappings — stop and get an ADR

JS semantics with no obvious Perl answer are catalogued in
[references/js-semantics.md](references/js-semantics.md), each with what
upstream does and the ticket that decides it. If your change depends on one that
is still open: do not pick a mapping locally. Finish what does not depend on it,
and report the blocker. The mechanism, once decided, lives in **one** place
(`Runtime` or `Lib`) — never re-derived inline in a filter.

## Tests

Three layers, all under `t/`, all runnable without node:

- **Ported upstream tests** — `upstream/nunjucks/tests/<x>.js` → `t/upstream/<x>.t`,
  one `subtest` per upstream `it(...)`, same title, same order. An upstream test
  that cannot be ported is a `TODO`/`skip` naming the ADR or ticket — never
  silently dropped, because the count is how coverage of the port is audited.
- **Corpus** — `t/corpus/*.json`: oracle input cases **with the oracle's output
  committed** as `expected`. `maint/corpus-regen` rewrites `expected` from the
  oracle; `t/corpus.t` replays the cases against the Perl port. Add cases freely:
  a new case costs one JSON object. Expected values are never typed by hand.
- **Perl-side API tests** — `t/NN-*.t`, for what has no upstream counterpart
  (the Perl API surface, coderefs in context, loaders on disk).

`xt/oracle-live.t` re-runs the corpus against the live oracle and fails if a
committed `expected` is stale. It needs `upstream/`; it is an author test.

Run everything with `prove -lr t/` — **`-r` is mandatory**, `t/upstream/` is a
subdirectory and plain `prove -l t/` silently skips it.

## Working a porting ticket

1. Read the upstream file end to end, then its `tests/<x>.js`.
2. Port top to bottom, function by function, names and order preserved.
3. Probe anything surprising with the oracle *before* writing Perl for it:
   `echo '{"template":"{{ [1,2] + 1 }}"}' | node maint/oracle.js`
4. Add the surprising probes to `t/corpus/` — they are the regression tests.
5. A deliberate difference needs an ADR in `docs/adr/` (next free number) in the
   same change. "Perl can't do that" is a reason; "this is cleaner" is not.

## Related

- `getty-perl-core`, `getty-perl-moo` — house Perl style; they win on *style*,
  upstream wins on *structure and behaviour*.
- `kanban-issues-karr-cli` — the board the port is tracked on.
