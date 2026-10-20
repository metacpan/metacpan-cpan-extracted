# FitNesse acceptance transport migration findings

## Configuration and attribution

Both acceptance runners accept `--transport pipe|tcp`. Pipe is the default; TCP remains an explicit external-listener mode. Each run extracts the pinned v20251025 wiki into an isolated root and starts a bounded FitNesse HTTP server. Pipe mode configures the temporary wiki to launch the repository's Perl runner on port `1`; TCP mode starts and probes an external Perl listener. Both modes verify actual execution through execution logs, and TCP additionally verifies its listener request/response trace.

The `fitnesse.jar -c` URL override can launch the Perl child for an ordinary page, but the runners use an HTTP server because nested PageDriver fixtures must issue requests to the same live FitNesse instance. Pipe runner defaults are written only in the temporary extracted wiki. Upstream pages are unchanged.

Commands:

```sh
bin/test-fitnesse                         # pipe (default)
bin/test-fitnesse --transport tcp
bin/test-fitnesse-suite                   # pipe (default)
bin/test-fitnesse-suite --transport tcp
```

## Runner argument compatibility

FitNesse v20251025 forwarded page-level `SLIM_FLAGS` as real child arguments. `PartiallyWorking_SettingSlimFlags` launched:

```text
/workspaces/test-slim/bin/perl-slim -v -s 1 1
```

The previous Perl entry point accepted only one positional port and exited 255. Consequently, FitNesse returned no result for the page and the default pipe CI step failed. `bin/perl-slim` now accepts `-v` (request/response diagnostics on stderr), `-s <seconds>` (per-statement fixture timeout), and one port in any option order; unsupported or malformed options still fail. Port `1` selects pipes, and other valid ports select TCP. Tests launch the executable as a child in both modes and verify the greeting, timeout response, later statement execution, and clean `bye` exit.

For the individual timeout page, Perl pipe mode reports 8/0/0/1 (right/wrong/ignored/exceptions). Its single timeout is intentional under `-s 1`; the following statements execute. A Java v20251025 child control for the same unchanged page reported 7/0/0/12 and exited 0. Java's future-based timeout and Perl's statement-boundary interruption do not have identical task-continuation semantics, so the Perl result remains explicitly nonconformant. The externally running TCP listener does not receive page child flags and retains its reviewed 9/0/0/0 result.

The individual pipe page `TestSystemSlimSuite.ErrorSituationsDuringSlimServerStartup.C_TimeoutAsNoServerAtGivenSocket` reports 4/0/0/0, while TCP reports 3/1/0/0. Pipe mode has no listener at the page's target socket and therefore establishes the requested no-server condition. The per-transport expectation is explicit; no fake listener or altered assertion is used.

## Individual acceptance baselines

Both modes select and execute all 50 pages and verify the Perl backend for all 50. TCP remains exactly 45 conformant with totals 373/7/2/0. Pipe is also 45 conformant with totals 373/6/2/1. The two reviewed pipe-specific page tuples are stored in `transportExpectations.pipe.pages` in `docs/fitnesse-slim-acceptance-baseline.json`; every other page uses the shared TCP tuple. The status difference on the no-server page is balanced by the timeout page's intended timeout exception, so page conformance remains 45/50.

## Native suite baseline differences

Both modes select and execute exactly the same 93 pages. Pipe execution logs positively attribute three FitNesse-managed Perl child sessions. TCP logs and the listener trace verified 724 requests and 724 responses. Initially, `ScenarioLibraryTestSuite.ScenariosOnlyInSlimTests` differed because `configure_pipe_wiki` added `!define TEST_SYSTEM {slim}` to the temporary wiki root. That made generated `MySuite.TestPage` a Slim test even though the upstream page checks behavior outside its local test-system context. The acceptance suite already defines Slim where it needs it. Pipe configuration now adds only the runner, command pattern, and port defaults, leaving `TEST_SYSTEM` local to each page. This restored the scenario assertion without changing the fixture or upstream page. The pipe baseline was reviewed from 1/1 to 2/0 for this page; no other page changed. The remaining native per-page transport-specific tuples are:

| Page | TCP (R/W/I/E) | Pipe (R/W/I/E) | Cause |
|---|---:|---:|---|
| `TestSystemSlimSuite.ErrorSituationsDuringSlimServerStartup.A_TimeoutAsSlimHeaderNotReceived` | 2/2/0/0 | 4/0/0/0 | Pipe child startup sends the SLiM header; TCP's intentionally broken external startup condition differs. |
| `TestSystemSlimSuite.ErrorSituationsDuringSlimServerStartup.C_TimeoutAsNoServerAtGivenSocket` | 3/1/0/0 | 4/0/0/0 | Pipe mode leaves the target socket unoccupied; TCP's external-service configuration does not. |
| `TestSystemSlimSuite.ManualStartofSlimService` | 2/2/0/0 | 4/0/0/0 | Pipe launches the configured child, while this page tests a manually started external service. |

`TestExceptionIsDisplayed.ParameterConversionExceptions` is identical on both transports at 3/14/0/0; its earlier discrepancy resulted from rejecting `-v`. All other native page results match their reviewed expectations. The shared 93-page inventory is unchanged. Pipe per-page totals are now 543/41/5/315; the FitNesse suite's own final-count summary is 75/6/1/11. TCP remains 538/46/5/315, with suite final counts 72/9/1/11. Exact pipe expectations and explanations are in `transportExpectations.pipe` in `docs/fitnesse-slim-native-suite-baseline.json`; TCP expectations remain unchanged.

The generated `docs/fitnesse-acceptance-coverage.md` and JSON manifest reconcile the 50 isolated entries with the 93 native-suite entries. The four-way report in `.runtime/fitnesse-acceptance-matrix.md` compares all per-page results without overwriting the transport-specific result artifacts.

These are two explicit exact baselines, not a relaxed comparison. Every page remains selected and must produce a result, every tuple is compared, and missing/extra pages, child launch errors, test-system exceptions, timeouts, failed attribution, or unreviewed count changes fail the runner. `SLIM:remote_debug` labels are accepted only when the actual command names `bin/perl-slim` with port `1` and child exit status zero.

## Regression workflow

GitHub Actions runs `bin/test-dev`, the individual pipe gate, the native pipe gate, and both complete TCP acceptance gates. The TCP gates use the real external Perl listener; they do not infer TCP use from a displayed label. A locally passing run does not establish a remote Actions result; check the Actions run separately after pushing.
