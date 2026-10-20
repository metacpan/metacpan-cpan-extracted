# Test::FitNesse::Slim

Test::FitNesse::Slim enables FitNesse acceptance testing of applications
written in Perl. It implements the server side of FitNesse's SLiM (Simple List
Invocation Method) protocol and lets FitNesse invoke idiomatic Perl fixtures. The current
distribution version is 1.00. The declared minimum is Perl 5.36.0. The full
development and FitNesse acceptance suites are verified with Perl 5.40.1; a
dedicated CI job tests configuration, build, installation, development tests,
and the installed pipe service on Perl 5.36. FitNesse integration is tested
against v20251025.
This is not a claim of full compatibility with Java reflection, Java-only
plugins, or every FitNesse integration.

Known boundaries include Java reflection and overload-based fixture APIs,
Java-side comparator/rendering plugin context in nested PageDriver tests,
and FitNesse's Nashorn-backed table expressions. These are described in
the compatibility documents indexed below.

## Install

After the distribution is available from CPAN, install it with:

```sh
cpanm Test::FitNesse::Slim
```

To install from a source checkout or release archive, install declared
dependencies, then build with Module::Build:

```sh
cpanm --installdeps .
perl Build.PL
./Build
./Build test
./Build install
```

For a local prefix:

```sh
perl Build.PL --install_base="$HOME/perl5"
./Build
./Build install
export PATH="$HOME/perl5/bin:$PATH"
export PERL5LIB="$HOME/perl5/lib/perl5${PERL5LIB:+:$PERL5LIB}"
```

The runtime dependency is `HTML::TreeBuilder`. Build/test prerequisites are
listed in `cpanfile` and `Build.PL`. `perldoc Test::FitNesse::Slim` describes the
server entry point; the `docs/` directory contains the developer and
compatibility reference.

## Start the service

For FitNesse-managed SLiM v0.5 pipes, configure the page, suite, or FitNesse
root with:

```text
!define TEST_SYSTEM {slim}
!define COMMAND_PATTERN {%m}
!define TEST_RUNNER {/absolute/path/to/perl-slim}
!define SLIM_PORT {1}
```

The FitNesse process must inherit Perl's module path for external fixture
packages. For example:

```sh
export PERL5LIB="/path/to/my/fixtures:/path/to/perl5/lib/perl5${PERL5LIB:+:$PERL5LIB}"
```

FitNesse then launches `perl-slim 1`; stdin and stdout carry framed SLiM
messages. Protocol bytes use stdout exclusively. Fixture output is tunneled
through FitNesse's v0.5 diagnostic records on stderr.

For a separately managed TCP v0.5 listener, start:

```sh
perl-slim 8099
```

TCP binds to `127.0.0.1` by default. Configure FitNesse's SLiM host as
`127.0.0.1` and its port as `8099` (or the selected listener port). To bind
to a specific IPv4 address assigned to the host, use `--bind-address` before
or after the port:

```sh
perl-slim --bind-address 192.0.2.10 8099
```

Use `--bind-address 0.0.0.0 8099` to listen on all IPv4 interfaces. TCP does
not authenticate clients; access to the listener grants the ability to invoke
Perl fixtures. Remote binding is intended only for trusted networks. Loopback
binding limits network access but is not authentication or a sandbox; local
processes can still connect and invoke fixtures. Pipe mode is the normal
FitNesse-managed transport.

The command accepts `-v` for diagnostics and `-s SECONDS` for a per-statement
timeout before the port argument. Port `1` selects pipes and cannot be
combined with `--bind-address`; other valid ports select TCP. The same
`bind_address` option is available through `Test::FitNesse::Slim::Server->new`.

## External fixture example

The standalone fixture in `examples/lib/Example/Counter.pm` uses an integer
constructor argument, maps the SLiM method `addAmount` to Perl's
`add_amount`, and declares typed argument/result conversion. Its FitNesse
page is `examples/fitnesse/CounterTest.wiki`.

Copy `examples/lib/Example/Counter.pm` from the extracted distribution into
an external fixture directory, then include both that directory and the
installed module directory in `PERL5LIB`. Replace the placeholder paths in
`examples/fitnesse/CounterTest.wiki` with the installed executable and
fixture directory, and copy the page content into a FitNesse page. Use the
pipe configuration above; the page should report two passing assertions.
The fixture conversion contract and complete invocation example are in
[`docs/fixture-conversion.md`](docs/fixture-conversion.md).

## Business-oriented acceptance example

[`examples/order-management/`](examples/order-management/README.md) contains a
separate FitNesse suite for customer eligibility, pricing, inventory, and
order submission. It uses decision, script, query, ordered-query, and scenario
tables, and runs against a temporary installation of the packaged
distribution:

```sh
bin/test-example-order-management
bin/test-example-order-management --transport tcp
```

The runner includes wiki-only authoring exercises and verifies that the
installed Perl service handled the tests. It is separate from the upstream
50-page and 93-page regression inventories.

## Documentation

Start at [`docs/index.md`](docs/index.md) for the documentation map. The
acceptance baselines distinguish isolated-page checks from native FitNesse
suite execution and pipe transport from TCP; a baseline match means no
unexpected change relative to reviewed results, not complete SLiM
conformance.

## License

Copyright 2010-2026 Greg Bacon. The recipient may choose to use, modify, and
redistribute Test::FitNesse::Slim's original implementation under the GNU General Public
License version 1 or any later version, or Artistic License 1.0. The complete
texts are [GPL](LICENSE.GPL-1.0-or-later) and [Artistic](LICENSE.Artistic-1.0).
Test-only FitNesse fixture adaptations have separate Common Public License
terms; see [`LICENSE`](LICENSE) and
[`THIRD-PARTY-NOTICES.md`](THIRD-PARTY-NOTICES.md).
