# AGENTS.md

Read this first. Follow it exactly. Skipping steps will break CI,
block merges, corrupt stored sessions or make the maintainers unhappy.

## Presentation

- Web::Session is a fork of Apache::Session::Browseable: it adds
  searchable indexes to Apache::Session stores, for LemonLDAP::NG and
  other applications.

- It is written in Perl. Each backend is a pair of modules:
  `Web::Session::<Backend>` (the Apache::Session implementation) and
  `Web::Session::Store::<Backend>` (the storage layer). `Postgres`,
  `MySQL` and `MariaDB` are aliases of the JSON backends.

- The public API is Apache::Session's:
  `tie %session, 'Web::Session::PgJSON', $id, $args`, plus the class
  methods `searchOn()`, `searchOnExpr()`, `searchLt()`, `searchGt()`,
  `get_key_from_all_sessions()` and `deleteIfLowerThan()`.

- The build uses Module::Build:

  ```
  perl Build.PL
  ./Build
  ./Build test
  ```

  Never run `prove -l`: `lib/Web/Session/_common.pm` is autosplit
  (`autosplit` in `Build.PL`), so its methods live in `auto/` and only
  exist after a build. Use `./Build test` (or `prove -b` after
  `./Build`).

- Database tests run only when their environment variables are set
  (`PG_DSN`, `MYSQL_DSN`, `MARIADB_DSN`, `REDIS_URL`, `LDAP_URL`...);
  see `.github/workflows/ci.yml`. Without them, the suite still covers
  the File, SQLite and mocked paths.

- Also run the suite with the pure-Perl JSON backend:
  `PERL_JSON_BACKEND=JSON::PP ./Build test`.

## Code

- `use strict` everywhere; keep the surrounding Perl style (4-space
  indent, spacing inside parentheses, no new dependency without a
  reason).

- Every module has `our $VERSION = '1.0.0';` and a package name that
  matches its path. When adding a module, also add it to `MANIFEST`
  and copy the standard copyright block.

- Do not change the `@ISA` order of a store or backend: method
  resolution matters (`Web::Session::Store::DBI` must come before the
  Apache::Session store it specialises).

- SQL: bind every value (`?`). Never interpolate a value that is not
  validated first (`_isNumber()`, `_checkThresholds()`,
  `_checkSearchValue()`). Quote identifiers with
  `_quoteIdentifier()`/`_quoteColumn()`, never by hand.

- Keep the SQL expressions built by `_buildLowerThanExpression()` and
  `_buildCompareExpression()` exactly identical to the documented
  index expressions: the tests in `t/Web-Session-lowerThan.t` and the
  `explain` groups of `t/lib/SQLBackendTests.pm` depend on it.

- Connections: a handle must not be used or closed by a child created
  by `fork()`. The `connect_cached()` path uses
  `_common::_forkSafeAttr()`; the PostgreSQL pool uses
  `AutoInactiveDestroy` and pid checks. Preserve both when touching
  `connection()`, `DESTROY` or the pool.

- Transactions: each store opens its connection with the attributes of
  the Apache::Session store it derives from (`AutoCommit` on for MySQL,
  off for PostgreSQL/SQLite/Patroni). Do not align them "for
  consistency": the rationale is in `Store/DBI.pm`.

- UTF-8: sessions are JSON text. Do not change the encoding or the
  serializer heuristics without the tests in `t/Web-Session-utf8*.t`,
  `t/Web-Session-Serialize-JSON.t` and the Redis/File/MySQL variants.
  Redis writes Latin-1 (`serializeLatin1()`); the SQL backends write
  UTF-8.

- `searchOn()` and `searchOnExpr()` propagate a failed query (they
  die). `searchLt()` and `searchGt()` never die on a database error:
  they print it on STDERR and, on the SQL backends, compare all
  sessions in Perl instead (a non numeric value is 0), returning `{}`
  only if that fails too. `deleteIfLowerThan()` prints the error and
  returns a false first value (`0` in scalar context); the second value
  is the number of sessions deleted before the failure (`0` unless a
  purge deleting in several steps, such as LDAP's or a batched one,
  failed midway), and LemonLDAP::NG then falls back to its full scan.
  LemonLDAP::NG's purge does not catch exceptions. Keep that contract; it is documented in
  "ERRORS" in `Web::Session`.

- A new backend needs: the two modules, an entry in `Build.PL`'s
  `recommends` if it has an optional driver, a test in `t/`, a
  `t/lib/SQLBackendTests.pm` configuration when it is SQL, a CI service
  and DSN, and POD with the schema and the recommended indexes.

## Code comments

- Comment only unconventional or tricky code: a non-obvious
  constraint, a workaround, a subtle ordering, a security-relevant
  detail.
- Never paraphrase the code. If the comment restates what the next
  lines do, delete it.
- No project history in comments: no "used to", "since 1.0", "fixed by
  #54". Exception: rare cases where the history is required to
  understand why the implementation looks the way it does.
- No design rationale in build files, scripts or config files. Link
  to the relevant POD instead, if anything.
- When you change code, update or remove the comments around it. An
  obsolete comment is worse than no comment: it misleads reviewers,
  auditors and agents.

## Documentation

- POD is the reference documentation: behaviour, options, schema,
  indexes and the differences between backends live in the module
  POD, updated in the same commit as the code.
- `README.md` is the entry point for users migrating from
  Apache::Session::Browseable: keep the backend table and the
  migration list accurate, and link to the POD instead of duplicating
  it.
- Record a significant decision once, in the module POD; do not
  duplicate it in comments, `Changes` or commits.
- There is no `docs/` folder: do not create one for a single feature.

## Specific files

### Changes

- Audience: administrators operating LemonLDAP::NG or another
  application that stores sessions.
- List user-visible changes only: new features, behaviour changes,
  removals, fixes, security notes.
- The `1.0.0` section describes the fork as released, not the
  intermediate steps taken during development. Rewrite entries rather
  than appending corrections.
- Released sections are never modified.
- Keep entries short; link to the POD for details.

### README.md

- Audience: users deciding whether to migrate from
  Apache::Session::Browseable.
- State only what changes for them: module names, removed backends,
  aliases, table conversion, serializer/generator names.

### MANIFEST

- Add every new file and remove deleted ones. Keep the list sorted;
  `./Build dist` must not report a missing or extra file.

### Build.PL

- `module_name`, `dist_version` and `autosplit` must stay in sync with
  the modules. `dist_version` is repeated in every `our $VERSION`.

### t/lib/SQLBackendTests.pm

- Shared suite for the SQL backends: add a group there instead of
  duplicating tests in each `t/Web-Session-<Backend>.t`.
- A `todo` group is a known bug of that backend. Remove it as soon as
  the bug is fixed: a TODO test that passes is a lost signal.

### .github/workflows/ci.yml

- New database, driver or backend: add the service, the DSN variables
  and, when relevant, a second run with another driver or version.

## Tests

- Every behaviour change gets a test. Prefer a test that needs no
  database (mock `DBI`, the Redis client or the Patroni API) when the
  logic allows it.
- Database tests go through `t/lib/SQLBackendTests.pm` and are skipped
  when the environment variable is missing; never make them mandatory.
- Run `./Build test` before submitting, then
  `PERL_JSON_BACKEND=JSON::PP ./Build test`.
- When you add a file, check that `./Build test` still finds it: the
  suite is driven by `t/*.t`, not by `MANIFEST`, but `MANIFEST` is
  checked by `./Build dist`.

## Git commit messages

- Audience: developers.
- A concise subject line, prefixed by the area when it helps
  (`Redis: ...`, `PgJSON: ...`, `Tests: ...`, `Document ...`), then a
  short body explaining why when it is not obvious. Not a diary, not a
  copy of the POD.
- Reference issues and pull requests in the body: this is where
  history belongs.
- Do not add AI/session trailers, `Claude-Session` links or similar
  references to commits, pull requests or comments.

## Before submitting

- [ ] `./Build test` passes, including `PERL_JSON_BACKEND=JSON::PP`.
- [ ] Database tests pass locally when a server is available, or the
      change is covered by a mocked test.
- [ ] New files are in `MANIFEST`; deleted files are removed from it.
- [ ] The POD documents the behaviour, options and indexes touched.
- [ ] SQL expressions still match the documented indexes and the
      `explain` tests.
- [ ] Every comment explains something non-obvious and still true.
- [ ] No history, issue numbers or rationale in comments or build
      files.
- [ ] `Changes` entries are written for administrators and reflect
      the current state.
- [ ] Commit messages are concise and explain why.
