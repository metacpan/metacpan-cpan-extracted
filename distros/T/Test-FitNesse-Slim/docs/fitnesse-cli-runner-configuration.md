# FitNesse CLI runner configuration

## Scope and method

This investigation used `/opt/fitnesse/fitnesse.jar` (FitNesse v20251025). Each `-c` experiment ran FitNesse as a short-lived process against a temporary wiki extracted from that JAR. It did not use or alter the repository's running FitNesse/Perl services, acceptance baselines, or upstream wiki pages. The test pages and suite were the unmodified pages from the pinned JAR. A temporary executable wrapper logged its arguments and then delegated to the Java `fitnesse.slim.SlimService` so the selected process could be positively identified while retaining a working SLiM server.

The pinned JAR's command-line guide describes `-c` as execution of a REST command URL. Bytecode inspection identified `COMMAND_PATTERN` and `TEST_RUNNER` in the test-system command builder, and `SLIM_PORT` in the Slim client builder. Runtime invocation logs and test-system XML were used as the primary evidence below.

## Findings

| Setting or behavior | Finding | Evidence |
|---|---|---|
| `COMMAND_PATTERN` query override | **Verified working.** | On `SlimSymbols.NamingConvention`, the wrapper was launched with `fitnesse.slim.SlimService` and `1`; XML recorded the wrapper command and the unmodified page had 5 right, 0 wrong, 0 ignored, 0 exceptions. |
| `TEST_RUNNER` query override | **Verified working as a resolved variable.** | Setting it to the deliberately nonexistent `fitnesse.slim.CliOverrideSentinel` changed the logged test-system command to that class. The default command pattern still launched Java, which failed to find the class and produced an exception. Thus this override alone does not select an executable wrapper. |
| Both `COMMAND_PATTERN` and `TEST_RUNNER` | **Verified working together.** | The wrapper was invoked with `CliRunnerMarker` and `1`; XML recorded `/tmp/.../slim-wrapper CliRunnerMarker 1`. The unmodified page passed 5/0/0/0. |
| `SLIM_PORT=1` | **Verified working as pipe-mode selection.** | The wrapper received final argument `1`. On a page that defines `SLIM_PORT {0}`, the CLI query override changed the launched value to `1`. FitNesse's Quick Reference defines `1` as stdin/stdout communication and `0` as automatic network-port selection. The wrapper then delegated to the Java service, which completed the test. |
| CLI parameters versus page variables | **Verified: query parameters win.** | `TextBeforeSlimHeaderIsIgnored` defines its own remote-debug `COMMAND_PATTERN`, runner, and `SLIM_PORT {1}`; the query values replaced the command pattern and runner, and the wrapper was launched. The startup-timeout page defines a nonexistent runner and `SLIM_PORT {0}`; query runner/port values replaced those definitions. |
| CLI parameters versus inherited variables | **Verified for `SLIM_PORT`.** | `SuiteAcceptanceTests/content.txt` defines inherited `SLIM_PORT {1}`. On `NamingConvention`, query `SLIM_PORT=0` changed the actual command argument to an automatically selected TCP port (`36679`) and the page passed 5/0/0/0. |
| Suite propagation | **Verified working.** | `ScenarioTestSuite?suite&format=xml` received the wrapper command and runner marker. Suite execution logs recorded that command, the wrapper ran once with `SuiteRunnerMarker` and `1`, and all six child page result entries were present with no exceptions. |
| Precedence against Java `-D` properties or `plugins.properties` | **Unverified.** | The experiments compare URL values with page and inherited wiki variables. They do not establish precedence against JVM properties or plugin configuration. These are separate FitNesse configuration mechanisms. |

For the direct `NamingConvention` experiments, the command URL was the control URL above with each suffix appended in turn:

```text
?test&format=xml&COMMAND_PATTERN=%2Ftmp%2F...%2Fslim-wrapper%20%25m
?test&format=xml&TEST_RUNNER=fitnesse.slim.CliOverrideSentinel
?test&format=xml&COMMAND_PATTERN=%2Ftmp%2F...%2Fslim-wrapper%20%25m&TEST_RUNNER=CliRunnerMarker
?test&format=xml&SLIM_PORT=0
```

The page-defined-variable check used `TextBeforeSlimHeaderIsIgnored` with `COMMAND_PATTERN=%2Ftmp%2F...%2Fslim-wrapper%20%25m&TEST_RUNNER=PageOverrideMarker&SLIM_PORT=1`; the runner/port conflict check used the startup-timeout page with `COMMAND_PATTERN=%2Ftmp%2F...%2Fslim-wrapper%20%25m&TEST_RUNNER=CliRunnerMarker&SLIM_PORT=1`. The suite check used `ScenarioTestSuite?suite&format=xml&COMMAND_PATTERN=%2Ftmp%2F...%2Fslim-wrapper%20%25m&TEST_RUNNER=SuiteRunnerMarker&SLIM_PORT=1`. The abbreviated `/tmp/...` portions above stand for the same absolute temporary wrapper path, encoded with each slash as `%2F`; the full, portable command form appears below.

### Java reference control

The control invocation was:

```sh
java -jar /opt/fitnesse/fitnesse.jar \
  -d "$TASK_ROOT" -r FitNesseRoot -p 19321 -b "$TASK_ROOT/control.xml" \
  -c 'FitNesse.SuiteAcceptanceTests.SuiteSlimTests.SlimSymbols.NamingConvention?test&format=xml'
```

It exited 0. The execution XML identified `slim:fitnesse.slim.SlimService` and logged the actual command `java -cp /opt/fitnesse/fitnesse.jar fitnesse.slim.SlimService 1`; the page result was 5 right, 0 wrong, 0 ignored, 0 exceptions. The inherited port value `1` selected the Java service's standard input/output pipe transport for this control.

### Override syntax and URL encoding

The values are URL query parameters on the `-c` command URL. FitNesse decodes them before resolving test-system variables. For example, `%m` in a command pattern must be encoded as `%25m`, spaces as `%20`, and a slash in a path as `%2F`. Quote the complete URL for the shell so `&` remains part of the URL.

This tested form replaced a page-defined command pattern and runner, and caused an executable wrapper to run. The wrapper delegated to the Java service; it was not a Perl transport test:

```sh
java -jar /opt/fitnesse/fitnesse.jar \
  -d "$TASK_ROOT" -r FitNesseRoot -p 19321 -b "$TASK_ROOT/result.xml" \
  -c 'FitNesse.SuiteAcceptanceTests.SuiteSlimTests.TestSystemSlimSuite.TextBeforeSlimHeaderIsIgnored?test&format=xml&COMMAND_PATTERN=%25m&TEST_RUNNER=%2Fabsolute%2Fpath%2Fto%2Fslim-wrapper&SLIM_PORT=1'
```

With `COMMAND_PATTERN=%m`, FitNesse ran the `TEST_RUNNER` executable directly and appended the selected port argument (`1`). The wrapper's argument log contained exactly `1`; the XML command was `/tmp/.../slim-wrapper-direct 1`; the page passed 2/0/0/0. This page also has its own `COMMAND_PATTERN`, so the result establishes that the URL override can replace it.

For a suite, the equivalent shape is:

```sh
java -jar /opt/fitnesse/fitnesse.jar \
  -d "$TASK_ROOT" -r FitNesseRoot -p 19321 -b "$TASK_ROOT/suite.xml" \
  -c 'FitNesse.SuiteAcceptanceTests.SuiteSlimTests.ScenarioTestSuite?suite&format=xml&COMMAND_PATTERN=%25m&TEST_RUNNER=%2Fabsolute%2Fpath%2Fto%2Fslim-wrapper&SLIM_PORT=1'
```

`COMMAND_PATTERN=%m` relies on `TEST_RUNNER` being an executable path. A pattern such as `%m` is a FitNesse substitution pattern, not a shell command; add any required arguments explicitly using correctly encoded URL content. The tested wrapper accepted the port argument and delegated to Java. The CLI command is also documented in the pinned JAR's `ControllingFitNesseFromTheCommandLine` wiki page. The official [FitNesse Quick Reference](https://fitnesse.org/FitNesse.UserGuide.QuickReferenceGuide.html) describes `SLIM_PORT=1` as stdin/stdout mode and `0` as automatic port selection.

## Direct tests and suites

Both modes honor the query overrides. The direct test used a page with a page-defined runner/command pattern for an explicit precedence check. The representative suite used six child pages; execution XML showed per-page results and one wrapper launch reused by the suite's Slim test system. This confirms propagation for the tested suite execution path. Other responder types and nested `PageDriver` request behavior were not tested.

## Implication for a Perl pipe runner

**Verified:** FitNesse v20251025 can be directed, entirely by the `-c` URL, to use a chosen executable, command pattern, and `SLIM_PORT=1`. The query values override page and inherited wiki values in the tested cases. The earlier wrapper experiment established process selection; a subsequent implementation now proves actual Perl pipe interoperability. In a fresh wiki extracted from the pinned JAR, this command launched the repository's executable directly:

```sh
PERL5LIB="$PWD/lib:$PWD/t/lib" java -Dslim.pool.size=1 \
  -jar /opt/fitnesse/fitnesse.jar \
  -d "$TASK_ROOT" -r FitNesseRoot -p 19321 -b "$TASK_ROOT/result.xml" \
  -c 'FitNesse.SuiteAcceptanceTests.SuiteSlimTests.SlimSymbols.NamingConvention?test&format=xml&COMMAND_PATTERN=%25m&TEST_RUNNER=%2Fworkspaces%2Ftest-slim%2Fbin%2Fperl-slim&SLIM_PORT=1'
```

FitNesse v20251025 exited 0. The execution XML recorded `testSystem=slim:/workspaces/test-slim/bin/perl-slim`, command `/workspaces/test-slim/bin/perl-slim 1`, and 5 right, 0 wrong, 0 ignored, 0 exceptions. A second symbol page recorded the same child command and 18 right, 0 wrong, 0 ignored, 0 exceptions. The Perl child selected the pipe branch before any TCP listener is created. Process-level tests separately verified its `Slim -- V0.5` greeting and framing.

The `PERL5LIB` setting is required in this checkout because the child must find the implementation under `lib/` and acceptance fixtures under `t/lib/`. The existing `bin/test-fitnesse` and `bin/test-fitnesse-suite` remain TCP-based and unchanged; they do not migrate to this CLI path automatically.

The Perl pipe implementation now emits the pinned v20251025 `SOUT`/`SERR` records and FitNesse reconstructs fixture output into separate stdout/stderr execution-log sections. A temporary six-assertion page was verified against the Perl child and Java SlimService; detailed records, behavior, and the prefix-role discrepancy with the published guide are in [`slim-pipe-transport.md`](slim-pipe-transport.md).

Both acceptance runners support `--transport pipe|tcp`; pipe is selected by default. The long-lived isolated FitNesse HTTP service is retained so nested PageDriver requests have a live server. Pipe mode applies runner variables as temporary root wiki defaults and, for the native suite responder, query overrides. The `-c` mechanism is verified for direct and suite execution, but its short-lived mode is unsuitable for nested PageDriver pages that call back into a live FitNesse HTTP server. FitNesse also forwards page-level `SLIM_FLAGS` to a managed child. `bin/perl-slim` implements the relevant `-v` diagnostics and `-s <seconds>` statement timeout options; process-level tests cover the exact `-v -s 1 1` invocation. Reviewed, transport-specific results are documented in [`fitnesse-acceptance-pipe-migration.md`](fitnesse-acceptance-pipe-migration.md), and each gate compares exact per-page tuples against its selected transport expectations.

## Conclusions by status

- **Verified working:** `COMMAND_PATTERN`, `TEST_RUNNER`, and `SLIM_PORT` can be supplied as `-c` URL query parameters; query values override page definitions for all three in tested cases; query `SLIM_PORT` overrides an inherited value; the tested suite propagates the overrides; `SLIM_PORT=1` selects the documented pipe mode.
- **Verified not working:** Supplying only `TEST_RUNNER` does not make that value an executable command under the default Java command pattern. A matching `COMMAND_PATTERN` is required to select a custom executable.
- **Unverified:** Precedence against JVM system properties or plugin configuration; all suite/nested responder variants; inherited pipe transport across every nested PageDriver responder path.
