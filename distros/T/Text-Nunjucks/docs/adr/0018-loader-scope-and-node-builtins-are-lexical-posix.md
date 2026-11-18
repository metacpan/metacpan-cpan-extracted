# ADR 0018 — Loader scope, and node's path/fs/console built-ins as lexical POSIX ports

- Status: accepted
- Date: 2026-11-13
- Tags: loaders, node, scope, decision, k19, k37

## Context

Upstream ships four loaders. `src/node-loaders.js` has `FileSystemLoader` and
`NodeResolveLoader`, and re-exports `PrecompiledLoader`. `src/web-loaders.js`
has `WebLoader`. `src/precompiled-loader.js` has `PrecompiledLoader`.
`Environment.init` (environment.js) defaults to `[new FileSystemLoader('views')]`
when there is a `FileSystemLoader`, which is the case under node, and to
`[new WebLoader('/views')]` in a browser. `FileSystemLoader`'s `watch` option
`require`s the optional peer dependency chokidar. When chokidar is missing,
upstream throws `watch requires chokidar to be installed`.

The loaders call node built-ins, not Nunjucks code:

- `loader.js` `resolve` calls `path.resolve(path.dirname(from), to)`.
- `FileSystemLoader` calls `path.normalize`, `path.resolve`, `fs.existsSync`,
  `fs.readFileSync(p, 'utf-8')` and `console.log`.

Their Perl look-alikes behave differently:

- **`Path::Tiny->absolute` does not collapse `..`.** It is what `Loader::resolve`
  used through k16 (self-flag on k19). From `views/sub/page.njk`, `../d.njk` gives
  node `<cwd>/views/d.njk` but gave the port `<cwd>/views/sub/../d.njk`. The
  results are different cache keys and a different path in error prefixes.
- **`->realpath` and `File::Spec` do not match either.** `->realpath` asks the
  file system and resolves symlinks. `File::Spec` does not collapse `..` at all.
- **Encode's strict UTF-8 decoder replaces malformed bytes differently.** It
  writes one U+FFFD per malformed sequence. Node's WHATWG decoder writes one
  U+FFFD per maximal subpart, so `C0 80` becomes two, `ED A0 80` three and
  `F4 90 80 80` four (oracle). Encode also refuses the noncharacter U+10FFFF,
  which node decodes.

## Decision

**Scope.** The scope is the maintainer's decision, written on card k19: the
FileSystem and Precompiled loaders are ported, while `NodeResolveLoader`,
`WebLoader` and chokidar `watch` are out of scope. How `watch` behaves without
chokidar was chosen by the main agent when it routed k19 (2026-11-13). The
maintainer did not decide that part.

- **Ported 1:1:** `FileSystemLoader` is `Text::Nunjucks::Loader::FileSystem` and
  `PrecompiledLoader` is `Text::Nunjucks::Loader::Precompiled`. Both keep
  upstream's functions, order and control flow, as `Loader` subclasses with
  positional constructors.
- **Out of scope (maintainer):**
  - `NodeResolveLoader`, which is `require.resolve` over `node_modules`.
  - `WebLoader`, which is XHR in a browser.
  - chokidar `watch`.
- **The port acts as upstream installed without chokidar (main agent's
  choice).** It is what upstream itself does when chokidar is absent. A truthy `watch`
  throws upstream's own `Error('watch requires chokidar to be installed')`.
  `maint/oracle.js` hides chokidar from `require` so that the oracle measures
  the same branch. Without that, a watch case would also start a watcher and
  keep node running.
- **`Environment.init` always takes the node branch.** That is the default
  `[FileSystemLoader('views')]`. Its browser branches, `WebLoader('/views')` and
  `window.nunjucksPrecompiled`, have no image.

**node built-ins are `Lib` seams, ported from node's own source.** Every one of
them is a `Text::Nunjucks::Lib` `node_*` function, and no other module calls
node-like path or file code:

- `node_path_resolve`, `node_path_normalize` and `node_path_dirname` are
  `posix.resolve`, `posix.normalize` and `posix.dirname`, with their shared
  `normalizeString` as `_node_normalize_string`.
  - **Source.** They are ported function by function from `lib/path.js` of
    node v24.19.0, the node the oracle runs, read from that node itself
    (`process.binding('natives').path`).
  - **Lexical.** `.` and `..` collapse on the string, the file system is never
    asked, and symlinks stay as they are.
  - **POSIX.** The separator is `/` and only `/`, and a backslash is an ordinary
    character.
  - **The working directory.** Only `resolve` reads it, through
    `node_process_cwd` (`getcwd(3)`, physical, as libuv's `uv_cwd`), and it
    keeps node's shortcut that `resolve()`, `resolve('')` and `resolve('.')`
    return the cwd unchanged.
  - **Callers.** `Loader::resolve` is
    `node_path_resolve(node_path_dirname(from), to)`. `FileSystemLoader` uses
    `normalize` on each search path, then `resolve(searchPath)` and
    `resolve(searchPath, name)` in `getSource`.
  - **Arguments.** Each checks its arguments first, as node's `validateString`
    does (`_node_validate_string`), because a search path is whatever the
    caller passed `FileSystemLoader`. Anything but a string throws node's
    `ERR_INVALID_ARG_TYPE`, a `TypeError` (ADR 0010):
    `The "path" argument must be of type string. Received null` for
    `normalize` and `dirname`, `The "paths[1]" argument ...` for `resolve`.
    `resolve` checks only the arguments its loop reaches, from the last one
    back to the first absolute one, so `resolve(5, '/a')` is `/a`. How the
    value is shown is node's `determineSpecificType`
    (`_node_determine_specific_type`), over the kinds the port models:
    `undefined`, `null`, `type number (5)` (and `(-0)`, `(NaN)`,
    `(Infinity)`), `type boolean (true)`, `function ` plus the function's
    name, which a Perl coderef does not have (k88), and `an instance of`
    plus the constructor's name: `Array`, `RegExp`, `String` for a SafeString,
    `Object` for a dict, a caller hash or keyword arguments. A plain object
    with an own `constructor` member is shown through it, as node reads it:
    `{'constructor': {'name': 'Foo'}}` gives `an instance of Foo`, a falsy or
    nameless one `[Object]`, and a truthy primitive (`{'constructor': 1}`)
    makes V8 throw `Cannot use 'in' operator to search for 'name' in 1`
    instead. Any other blessed object is a plain object to the port
    (ADR 0016) and gives `an instance of Object`; that is the port's choice,
    as it has no JS counterpart. So a `Path::Tiny` object is no search path,
    as a JS `String` object is none to node.
- `node_fs_exists_sync` is `fs.existsSync`. It returns false for a path holding
  NUL, as node does for an invalid path, and otherwise is `-e` on the path's
  UTF-8 bytes.
- `node_fs_read_file_sync_utf8` is `fs.readFileSync(p, 'utf-8')`.
  - **Decode.** It reads the raw bytes and decodes them as node's WHATWG UTF-8
    decoder does (`_node_utf8_decode`). A BOM stays a U+FEFF character, and
    every maximal subpart of an ill-formed sequence becomes one U+FFFD. The
    result is a Perl character string under ADR 0012's I/O contract.
  - **No lock.** It is a plain `open` and `read`, as node's `open(2)` and
    `read(2)`. `Path::Tiny`'s `slurp` takes `flock(LOCK_SH)` first, which
    waits while another process holds `LOCK_EX` (node reads at once) and fails
    where `flock` is not supported.
  - **Errors.** A failure throws node's error as a `Lib::Error` (ADR 0010,
    name `Error`). Its message is libuv's `<CODE>: <description>, <syscall>`,
    followed by ` '<path>'` where node gives one. A failed `open` names the
    path: `EACCES: permission denied, open '<path>'`, and `ENOENT: no such
    file or directory, open '<path>'` for a dangling symlink. A failed `read`
    does not: `EISDIR: illegal operation on a directory, read`. The
    descriptions come from node's `util.getSystemErrorMap()` for the codes a
    read can produce (EACCES, EIO, EISDIR, EMFILE, ENFILE, ENOENT, EPERM). The
    code is the errno's name, libuv's where the system has two (`EAGAIN`, not
    `EWOULDBLOCK`; `ENOTSUP`, not `EOPNOTSUPP`), otherwise the first name in
    sort order.
- `node_console_log` is `console.log` of one string: the string and `"\n"` on
  STDOUT, which is where node's `console.log` writes. The only `console.log` in
  ported code is `FileSystemLoader`'s warning about a boolean second argument.
  The port keeps that warning, and it is not mapped to `warn`/STDERR.

**The search-path guard is ported as is.** `getSource` admits a file only if
`p.indexOf(basePath) === 0 && fs.existsSync(p)`. That is a string-prefix test,
so a sibling directory whose name extends the search path's passes it. For
search path `views`, `../views2/secret.njk` renders (oracle). It is an upstream
bug and is ported per ADR 0004; k95 tracks it. Reporting it upstream is the
maintainer's call.

**The Environment's loader listeners hold weak references.** This is the
worker's interim choice on k19, not a maintainer decision. Upstream's
`_initLoaders` closures capture `this` and `loader`. Strong Perl captures would
make a cycle (Environment → loaders → loader → listener → Environment) that
outlives every caller. The port captures both weakly. A template cannot see
the difference, but the Perl API can. Take a loader shared by two
Environments, with a `load` listener on each. If the caller drops the first
Environment, node keeps it alive through the loader's listener, so its `load`
listener still fires when the second Environment loads a template. The port
frees the first Environment, and its listener goes with it.
`t/10-loader.t` ("an Environment and its loader are freed once dropped")
asserts the port's behaviour. How to break the cycles for good is k96, which
also covers the cache cycle below.

**Fixtures.**

- **Upstream's suite fixtures are reused, not copied again.** `tests/templates`
  is `t/upstream/templates`, which has been present since k21. The card first
  asked for a separate `t/templates/` copy.
  `t/upstream/templates` lacks upstream's `relative/` directory, which only
  `tests/api.js` uses, so it comes with k38.
- **The port's own loader fixtures are `t/data/loader/`.** It holds `views/`,
  the sibling `views2/` and an `outside.njk` above both. They cover relative
  `../` includes and extends, the prefix guard, a missing template, a BOM file,
  a malformed-UTF-8 file and directories as names.
- **The oracle has a file-system case form.** Its keys are `fileSystemLoader`
  (`{searchPaths, opts}`), `defaultLoader` and `cwd`. It reports the repository
  root as `<root>` and records `stdout`. `t/corpus/render-loaders.json` holds
  those cases, and `t/corpus.t` replays them through
  `Text::Nunjucks::Loader::FileSystem`.
- **The upstream suites still render through a MemoryLoader.** Upstream's
  `tests/util.js` renders through `FileSystemLoader(tests/templates)`, which
  reports a template's absolute path. The port's harness,
  `t/lib/Test/Nunjucks/Util.pm`, still uses its in-memory loader, which reports
  the name as the path. Moving the suites over is a change of its own (k98).

## Consequences

- **The node behaviour is pinned.** `maint/node-builtins-fixtures` refuses any
  node but v24.19.0 and is deterministic. It writes `t/data/node-builtins.json`:
  1861 path cases (normalize, dirname, resolve over fixed and seeded random
  inputs), 186 cases of the same functions called with arguments that are no
  string, and 843 UTF-8 decode cases. `t/10-lib.t` replays them. A newer oracle
  node means reading its `lib/path.js` again and re-pinning, as for the V8 sort
  (ADR 0017).
- **ADR 0015 closes.** With `FileSystemLoader('views')` as the default loader,
  no transitional gap is left in `Environment.init`.
- **win32 is not modelled.** Node on Windows uses `path.win32` (drive letters,
  `\` as a separator, `posixCwd`'s win32 branch). The port uses POSIX
  everywhere, as on the oracle's platform. Whether Windows Perl needs it is
  k97.
- **Open items:**
  - *Duck-typed loaders (k94, decision).* Upstream's `_initLoaders` assigns
    `loader.cache = {}` to any object and tests
    `typeof loader.on === 'function'`. `tests/loader.js` `it` 1 and 2 pass
    loaders that only have `getSource`. A Perl object that is no
    `Text::Nunjucks::Loader` has no `cache` to assign. ADR 0016 has a read
    seam for properties of blessed objects but no write seam, so those two
    `it`s stay TODO until k94 settles it.
  - *A cached template keeps its Environment alive (k96).* A template cached
    in `loader.cache` holds its Environment, so Environment → loaders → loader
    → cache → Template → Environment is a cycle. It existed before k19 for
    every caching loader. `FileSystemLoader` without `noCache` is the first
    default that reaches it. The weak listener captures above are part of the
    same question.
  - *A function's name.* A Perl coderef has no name (k88), so a coderef as a
    path argument shows as `function ` and as an own `constructor` member as
    `an instance of `. In JS a function written as an object member takes the
    member's name (`an instance of constructor`).
  - *Lone surrogates in a path.* Node encodes a lone surrogate as U+FFFD.
    `utf8::encode` produces Perl's extended encoding of the surrogate instead.
  - *Unlisted errnos.* An errno outside the table falls back to the lowercased
    `strerror` text, which can differ from libuv's description.
  - *`PrecompiledLoader` name lookup.* `this.precompiled[name]` with an
    Object.prototype name (`constructor`, `toString`) finds that member
    upstream. In the port it finds nothing (k87).
- Reversible only by a maintainer decision to bring one of the out-of-scope
  loaders or `watch` into scope.
