# SLiM v0.5 stdin/stdout transport

## FitNesse v20251025 contract

The [SLiM protocol guide](https://fitnesse.org/FitNesse/UserGuide/WritingAcceptanceTests/SliM/SlimProtocol.html) defines port `1` as communication over the child's stdin/stdout. FitNesse invokes the configured test runner with the port argument; for this mode the argument is `1`. The child sends the unframed `Slim -- V0.5\n` greeting. Every subsequent message, including `bye`, remains length-prefixed: the outer length counts transmitted bytes, while string lengths inside serialized lists count UTF-16 code units. FitNesse and the child exchange repeated request/response frames until `bye` or pipe closure.

The published guide says FitNesse sends `bye` and the server shuts down. There is no additional version-negotiation message. TCP also sends `Slim -- V0.5\n`, as verified against the pinned FitNesse v20251025 `SlimVersion`. Both transports retain their respective connection lifecycle while sharing framing, parsing, response serialization, and executor state.

The executable accepts `bin/perl-slim [-v] [-s seconds] port`. FitNesse forwards `SLIM_FLAGS` before the port; `-v` writes request/response diagnostics to stderr, and `-s` bounds each fixture construction or method call in seconds. `bin/perl-slim 1` selects pipes; other numeric ports select TCP. Unknown flags and malformed/duplicate timeout options fail with usage text rather than being ignored.

The published guide specifies first-line prefixes `SOUT :` / `SERR :` and continuation prefixes `SOUT.:` / `SERR.:`. The pinned v20251025 JAR reverses those roles: reflection on `SlimPipeSocket` reports `FIRST_LINE_PREFIX=.:` and `FOLLOWING_LINE_PREFIX= :`; `LoggingOutputStream` emits `SOUT.:` or `SERR.:` first, then `SOUT :` or `SERR :` for later lines in that flushed message. A direct probe of the bundled logger produced `SOUT.:line\n` for one line, `SOUT.:one\nSOUT :two\n` for a two-line message, and `SOUT.:partial\n` for a partial line. A message containing only one line separator is suppressed. The implementation follows the pinned JAR and records this documentation discrepancy rather than treating the prose as authoritative over the installed client.

## Perl implementation

`Test::FitNesse::Slim::Server` shares one session loop for TCP and pipe transports. The loop receives separate input and protocol-output handles plus the greeting version. TCP passes the accepted socket in both directions and V0.5. `run(1)` branches to `run_pipe` before creating a listener. Pipe mode keeps a duplicate of the original stdout for protocol bytes and redirects otherwise-unscoped fixture stdout away from that descriptor. For each instruction batch, fixture fd 1 and fd 2 are redirected to separate disk-backed temporary files. Synchronous fixture output is read in bounded chunks and forwarded over the original diagnostic stderr before the next instruction is run. The protocol output still uses the shared exact-write routine.

Each pipe child owns one `ListExecutor` session. It reads and parses an entire framed request before executing it, preserves fixture and symbol state between batches, serializes and writes each response frame, and then waits for the next message. A framed `bye` returns normally and the child exits 0. EOF at a message boundary also returns normally and exits 0. EOF within a prefix or payload, malformed framing, invalid UTF-8, resource-limit violations, or corrupt serialized lists cause a diagnostic on stderr and a nonzero child exit; no response is fabricated for an incomplete/corrupt message. A well-framed malformed instruction still produces the regular `MALFORMED_INSTRUCTION` result and the session can continue. Writes handle partial progress and `EINTR`; pipe mode ignores `SIGPIPE` so a broken output pipe becomes a contained write error and nonzero child exit.

The frame size, decoded-list limits, and strict UTF-8 policy are identical to the TCP path. The pipe transport adds no separate parser, executor, listener, worker, or resource policy.

## TCP listener binding

Pipe mode is the normal FitNesse-managed transport. When TCP is selected, the
listener binds to IPv4 loopback (`127.0.0.1`) by default. The executable
accepts an explicit numeric IPv4 address, for example
`perl-slim --bind-address 0.0.0.0 8099`; the same option is available as
`Test::FitNesse::Slim::Server->new(bind_address => '0.0.0.0')`. Non-loopback binding
prints a warning to stderr. The TCP listener has no client authentication,
so remote access permits fixture execution and should be limited to a trusted
network. Loopback binding does not prevent local processes from connecting.
IPv6 binding is not supported.

## Diagnostic capture and forwarding

For each instruction, `ListExecutor::execute_with` invokes a small callback after execution and before dispatching the next statement. The callback drains that instruction's captured stdout and stderr as independent tunnel messages. Each message is line-oriented: the first line gets `SOUT.:` or `SERR.:`; later lines get `SOUT :` or `SERR :`. A final partial line is terminated for FitNesse's line reader. An output message consisting only of one newline is omitted to match the pinned Java logger; blank lines within a nonempty multiline message are retained. The original UTF-8 bytes are preserved, including multibyte and supplementary characters.

The separate temporary files prevent a fixture or a waited child process from blocking on a full pipe and keep output memory bounded. They are streamed to the FitNesse diagnostic pipe in 8 KiB chunks; large single lines do not need to be buffered in memory. Both captures are drained before each response frame and are removed on normal return. Fixture exceptions still produce their normal SLiM response after captured output is forwarded. If FitNesse closes its diagnostic pipe, forwarding errors are nonfatal to the SLiM response and session; a broken protocol-output pipe remains fatal. Truncated or malformed input has no fixture execution and produces no tunneling record.

Ordinary and explicit Perl `print`, raw writes to descriptors 1 and 2, and synchronous child processes inheriting those descriptors are covered. Output order within each stream is preserved. Because stdout and stderr are separately spooled and drained, the exact interleaving between the two streams is not guaranteed. Perl instruction calls are the record boundary; multiple writes from one method call are grouped together, whereas the Java logger's boundary is its `flush()` call. This difference does not change the reconstructed text and separate channels, but exact message grouping for a method that performs multiple flushes is not claimed. Detached child processes that continue writing after a fixture call returns and C stdio buffers that are not flushed before the call returns are also outside the verified boundary.

Unprefixed server error diagnostics still use process stderr; FitNesse logs such unprefixed text under stdout as specified. Routine frame-length debug messages are omitted in pipe mode so they do not appear as fixture output. TCP logging and protocol behavior are unchanged.

## Invocation

For a direct child runner, set a command pattern that expands to the runner executable and pass `SLIM_PORT=1`. FitNesse query values supplied to `-c` override tested page-defined and inherited wiki variables. In this checkout, `PERL5LIB` must include `lib` and `t/lib` so the child can load the server and acceptance fixtures.

```sh
TASK_ROOT=/tmp/test-slim-pipe-smoke
PERL5LIB="$PWD/lib:$PWD/t/lib" java -Dslim.pool.size=1 \
  -jar /opt/fitnesse/fitnesse.jar \
  -d "$TASK_ROOT" -r FitNesseRoot -p 19321 -b "$TASK_ROOT/result.xml" \
  -c 'FitNesse.SuiteAcceptanceTests.SuiteSlimTests.SlimSymbols.NamingConvention?test&format=xml&COMMAND_PATTERN=%25m&TEST_RUNNER=%2Fworkspaces%2Ftest-slim%2Fbin%2Fperl-slim&SLIM_PORT=1'
```

The FitNesse JAR's wiki was extracted into the temporary `TASK_ROOT` before running this command. The tested command exited 0. Its result XML reported FitNesse `v20251025`, test system `slim:/workspaces/test-slim/bin/perl-slim`, command `/workspaces/test-slim/bin/perl-slim 1`, and 5 right, 0 wrong, 0 ignored, 0 exceptions. The Perl child process therefore handled the page using port 1; no external Perl TCP listener was started or used. A second run of `SlimSymbols.SlimSymbolManipulation` used the same child command and passed 18/18 assertions.

The `TEST_RUNNER`-only query override is insufficient under FitNesse's default Java command pattern; `COMMAND_PATTERN=%m` is what makes FitNesse execute the runner path directly. `%m` must be URL-encoded as `%25m`, slashes as `%2F`, and the full URL should remain shell-quoted.

## Automated evidence and TCP compatibility

`prove -lv t/pipe-transport.t` launches `bin/perl-slim 1` as a child with connected pipes. The focused suite verifies exact pinned-JAR prefixes for regular and explicit stdout/stderr writes; per-instruction messages within a single request; multiline, partial, empty, Unicode, and >1 MiB output; alternating channels; output before exceptions; and output from a synchronous subprocess. It concurrently drains child stderr while reading protocol responses so the large-output case has a bounded timeout and cannot deadlock. It also checks the handshake, framed requests, multiple batches, state retention, null/empty values, `bye`, EOF, malformed input, broken diagnostic output, and child exit statuses. `t/list-executor-callback.t` verifies callback ordering and stop behavior.

An isolated FitNesse v20251025 test used a temporary page with six assertions and the actual Perl child (`/workspaces/test-slim/bin/perl-slim 1`). The result was 6 right, 0 wrong, 0 ignored, 0 exceptions; the child exit code was 0. Its execution XML placed `first output line`, both multiline output lines, and `Grüße / Tartu õun / Mae govannen 😀` in `<stdOut>`. It placed the matching error lines in `<stdErr>`. FitNesse removed all tunnel prefixes. A Java SlimService wrapper control ran the same temporary page with the same 6/0/0/0 result and reconstructed the same Unicode stdout and stderr. The Perl run's test-system and command fields identified the repository executable directly, and the Java wrapper log recorded its `1` argument.

Existing `t/server.t`, `t/server-frame.t`, `t/server-unicode-frame.t`, `t/server-malformed-input.t`, and the TCP listener tests continue to exercise the socket path. Both acceptance runners now expose `--transport pipe|tcp`; pipe is selected by default, and TCP mode remains a separately tested real-listener path. The current pipe acceptance results and outstanding test-system-specific differences are recorded in [`fitnesse-acceptance-pipe-migration.md`](fitnesse-acceptance-pipe-migration.md). The TCP runs still match their committed 50-page and 93-page baselines.

CI runs the individual and native acceptance suites by default through pipes and also runs both complete inventories through the real TCP listener. Transport-specific startup expectations are explicit in the corresponding JSON baselines; the expected page set is identical between transports.

Pipe protocol framing and real fixture stdout/stderr reconstruction are verified. That transport support does not imply that the existing TCP acceptance counts are transport-invariant: startup-timeout pages deliberately test connection availability and runner flags, and nested test-system pages run under a different lifecycle when FitNesse owns the Perl child. The acceptance runner fails on incomplete results and exact tuple changes rather than treating a successful child launch as a passing baseline.
