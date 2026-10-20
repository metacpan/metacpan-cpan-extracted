# Current design

This document summarizes the production architecture and points to the
more detailed source for each behavior. The documentation map is
[`docs/index.md`](docs/index.md). Acceptance and compatibility findings
remain in their audit reports so this design summary does not become a
second copy of those inventories.

## Runtime layers

`Test::FitNesse::Slim::Server` owns transport framing and a SLiM session. `Test::FitNesse::Slim::List`
parses and serializes nested values. The outer frame counts UTF-8 bytes;
inner string lengths count UTF-16 code units. `Test::FitNesse::Slim::ListExecutor`
executes decoded instruction batches through `Test::FitNesse::Slim::Statement` and
`Test::FitNesse::Slim::StatementExecutor`. A complete serialized request is decoded
before its first instruction executes.

Each session has isolated actor instances, registered libraries, imported
packages, symbols, converter registrations, and stop state. The statement
executor resolves methods in actor, declared System Under Test, then
newest-first library order. Fixture classes use imported package prefixes,
with the most-specific prefix preferred. Exact Perl method names precede
one camelCase-to-snake_case spelling; acronym boundaries are handled
without fuzzy matching. A declared `AUTOLOAD` is used only when neither
concrete name exists.

The executor applies only explicit fixture signature metadata. Typed
constructor and method signatures enforce fixed arity before conversion and
invocation. Fixture creation makes the object visible to its
`set_statement_executor` hook, then restores actor or library lookup state
if that hook fails. Rollback covers executor-owned registrations, not
external side effects. See [fixture conversion](docs/fixture-conversion.md)
for supported scalar, enum, array, and List/Collection conversions and the
Perl-specific boundaries.

## Transports and failure handling

Both supported transports speak SLiM v0.5 and share the same session
processing, serialization, and executor code. Port `1` selects one
FitNesse-managed stdin/stdout child session; other valid ports start the
forking TCP listener. Pipe protocol bytes use a preserved stdout descriptor.
Fixture stdout and stderr are captured separately and forwarded to
FitNesse using its v0.5 diagnostic records. See [pipe transport](docs/slim-pipe-transport.md)
for process ownership, output forwarding, and tested FitNesse evidence.
The TCP listener binds to IPv4 loopback by default; a numeric address can be
selected explicitly for trusted-network deployments. It does not authenticate
clients.

Malformed frames or serialized batches close only the affected session;
validly framed malformed instructions receive the standard SLiM exception
result. Defensive limits and the distinction between normative behavior
and Perl policy are recorded in [malformed input handling](docs/slim-protocol-malformed-input.md).

## Acceptance evidence

The acceptance infrastructure keeps two independent execution modes:

- `bin/test-fitnesse` runs the reviewed 50-page inventory as isolated page
  requests and clears generated nested pages between requests.
- `bin/test-fitnesse-suite` runs FitNesse's 93-page native suite traversal
  with its suite order and context.

Both modes support pipe and TCP. FitNesse owns the Perl process in pipe
mode; the runner owns the external listener in TCP mode. The four result
sets have separately reviewed per-page expectations. A match means no
unreviewed regression for that mode and transport, not complete SLiM
conformance. The exact population relationship and distinct coverage are
in [acceptance coverage](docs/fitnesse-acceptance-coverage.md); current
expected results are in the [individual](docs/fitnesse-slim-acceptance-baseline.md)
and [native-suite](docs/fitnesse-slim-native-suite-baseline.json) baselines.

The native FitNesse pages also exercise Java-side rendering, plugin
registration, startup configuration, and fixture classes that do not all
map to ordinary Perl fixture behavior. Their established boundaries and
assertion-level evidence remain in the [native suite audit](docs/fitnesse-native-suite-audit.md),
[fixture gap triage](docs/fitnesse-native-fixture-gap-triage.md), and
[rendering/comparator report](docs/fitnesse-rendering-comparator-compatibility.md).
FitNesse table expressions use Nashorn and Java objects and are not a SLiM
protocol feature; see [expression compatibility](docs/slim-symbol-expression-compatibility.md).

## Distribution and documentation

`Build.PL` uses Module::Build. `HTML::TreeBuilder` is the sole non-core
runtime dependency. The distribution declares Perl 5.36.0 as its minimum in
`Build.PL` and `cpanfile`; the full local development and acceptance matrix
has been verified on Perl 5.40.1, while CI targets the 5.36 release line
with development tests and an installed pipe smoke test. The root
`README.md` is included in the release archive. Test and acceptance tooling
dependencies are declared in both `Build.PL` and `cpanfile`; the
Module::Build compatibility release path uses simple version requirements.
`MANIFEST.SKIP` excludes local
FitNesse state, runtime output, downloaded archives, and workspace
configuration. The standard manifest task generates `MANIFEST`.

The installation smoke test always parses and renders POD from the installed
module. Module::Build manpage files are checked only when the active Perl
configuration defines manpage targets; `install_base` places those targets
under `PREFIX/man/man1` and `PREFIX/man/man3`. Perl builds configured with
`man1dir=none` or `man3dir=none` do not generate those files, so the test
reports the disabled target while retaining installed-POD validation. On
Windows, where `IO::Select` cannot poll ordinary process pipes, the portable
transport smoke test uses `IPC::Run` to supply a complete pipe request and
capture bounded child output. It uses `IO::Select` only for TCP socket
readiness. The test-only dependency is `IPC::Run` 20260322.0 or later, which
provides `finished`; the Windows job in the main workflow checks the loaded
version and required process methods before transport tests. It uses the Perl
smoke test for checkout and installed pipe/TCP checks. PowerShell only
orchestrates those commands. Installation isolation checks
compare resolved paths for both the loaded file and its expected location,
then verify the expected file lies beneath the resolved install prefix. This
accommodates filesystem aliases without accepting a similarly named sibling
directory. The Windows exploratory workflow skips the separate concurrent
TCP test: its `fork`/`TERM`/blocking-`waitpid` cleanup assumes Unix process
behavior that Strawberry Perl's pseudo-process emulation does not guarantee.
Linux and macOS retain the full concurrency test; Windows smoke evidence covers
only one TCP client. The listener keeps `SO_REUSEADDR` on Unix platforms and
sets it false on Windows because Winsock permits a reuse-enabled socket to
bind an occupied endpoint. This restores the tested default bind-conflict
behavior; it does not request `SO_EXCLUSIVEADDRUSE` or promise exclusive
protection from later binds.

The distribution installs the production modules and `bin/perl-slim`.
A custom `--install_base` prefix places modules under `PREFIX/lib/perl5`
and the executable under `PREFIX/bin`; add the module path to `PERL5LIB`
when it is not in Perl's default `@INC`. External fixture paths can be
added separately. `bin/test-install` builds and installs the archive in a
temporary prefix, loads a fixture copied outside both the checkout and
installed module tree, exercises pipe and TCP instructions, and runs the
packaged FitNesse page while verifying the installed Perl runner command.

Every production module and `bin/perl-slim` includes POD. The Markdown
hierarchy is indexed in [`docs/index.md`](docs/index.md). `bin/check-docs`
checks POD syntax and rendering plus local Markdown links; the POD tests
also check production method coverage.

The independent [order-management example](examples/order-management/README.md)
demonstrates business-readable FitNesse tables over a pure Perl application.
The domain stores records as hashes and line collections as arrays; fixture
adapters translate them to decision, script, query, ordered-query, and
scenario behavior. Query fixtures map hash records to named FitNesse columns;
script checks use named business operations and symbols for order identifiers.
The engine does not provide general hash-member expressions, and ordinary
hash results are formatted rather than retained as raw record symbols. Wiki
currency is parsed as decimal text into integer cents.
`bin/test-example-order-management` builds and installs the
distribution in a temporary prefix, copies the application outside the
checkout, and runs the pinned FitNesse suite against that installed engine.
Its authoring exercises include a field-level expected-value mismatch, but are
automated inspections, not evidence from nontechnical user research.
