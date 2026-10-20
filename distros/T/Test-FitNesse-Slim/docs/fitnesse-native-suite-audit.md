# Native FitNesse SLiM suite audit

## Summary

FitNesse **v20251025** selected and executed **93 page results** for `FitNesse.SuiteAcceptanceTests.SuiteSlimTests?suite`. The existing `bin/test-fitnesse` inventory remains a separate 50-page, page-by-page external-Perl gate. The exact set comparison is 48 shared pages, 45 native-suite-only pages, and 2 individual-inventory-only pages (95 distinct pages in the union). Machine-readable per-page data, including fully qualified paths, selection evidence, both controlled-run results, direct individual-page results, current baseline observations, and backend attribution, is in [`fitnesse-native-suite-audit.json`](fitnesse-native-suite-audit.json).

The controlled native suite was run twice on independently copied FitNesse wiki roots. Both runs selected the same 93 paths in the same order, with identical per-page counts. Crucially, **both native suite runs used the external Perl SLiM listener**. Their log labels included `slim:fitnesse.slim.SlimService`, `SLIM:fitnesse.slim.SlimService`, and `SLIM:remote_debug:fitnesse.slim.SlimService`, but the command logged for each was a connection to the configured Perl listener. FitNesse process tracing showed no Java SlimService child process. The separate Java-reference run described below was explicitly configured to start Java SLiM and is not part of either native suite run.

## Selection and reconciliation

FitNesse v20251025 `SuiteResponder` delegates selection to `SuiteContentsFinder` and `SuiteFilter`. With this `?suite` request there was no supplied suite-filter tag, so the `<Suites>` values on the root and nested pages did not limit selection. `SuiteContentsFinder` traverses test pages, observes `<Prune/>`, reads legacy wiki Test headers, and adds referenced pages. An empty `<Test/>` property is enabled in FitNesse's page model; it is distinct from a missing or false Test property.

The 93 selected paths break down as follows:

| Selection source | Selected pages |
| --- | ---: |
| Explicit `<Test>true</Test>` properties | 48 |
| Empty/self-closing `<Test/>` properties | 32 |
| Legacy `.wiki` Test headers | 10 |
| Referenced/support pages without a local Test marker | 3 |
| **Total** | **93** |

The wiki contains 50 explicit Test=true markers, 37 empty Test markers, and 10 legacy wiki Test headers. Pruning removes seven property-marked pages from native traversal: the two explicit-Test pages listed below and five empty-Test pages. Their exact full paths are also stored as `reconciliation.prunedTestPages` in the JSON audit, and the reproducible coverage generator checks that list against the pinned JAR. Thus 80 property-marked pages, 10 legacy-header pages, and 3 referenced pages execute.

The 50-page individual inventory has 48 pages in common with the native run. Its two pages absent from native selection are:

- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.TestSystemSlimSuite.HowtoEnforceA_TimelimitPerTestCommand.NotWorking_SettingSlimTimeout`
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.TestSystemSlimSuite.HowtoEnforceA_TimelimitPerTestCommand.PartiallyWorking_SettingSlimFlags`

Both have `<Test>true</Test>`, but their parent `HowtoEnforceA_TimelimitPerTestCommand` has `<Prune/>`. They pass in the individual Perl baseline. Their omission is native suite pruning, not missing inventory data.

The 45 native-only pages comprise 32 empty Test properties, 10 legacy Test headers, and 3 cross-reference/support pages. Their exact paths and markers are recorded in the JSON inventory. The generated [`fitnesse-acceptance-coverage.json`](fitnesse-acceptance-coverage.json) enumerates every page with a wiki content record in the subtree (including legacy `.wiki` files), its inventory membership, property marker, and reason when FitNesse did not produce a native result row. The `bin/test-fitnesse` drift check keeps its documented 50-page scope explicit; the separate `bin/report-fitnesse-coverage` command checks both committed page sets, the pinned wiki pages, and all seven audited prune exclusions.

## Controlled executions and backend evidence

Each counted run used an independent copy of `FitNesseRoot` with any generated `MySuite` directory removed before startup, FitNesse v20251025, an isolated HTTP port (18085 and 18086), and a separately started Perl server (18105 and 18106). Only historical top-level FitNesse version ZIP archives were removed from the copies; they are not page content and made writes to generated pages excessively slow. `TEST_SLIM_FITNESSE_URL` pointed nested PageDriver requests back to the same isolated FitNesse instance. Each native `?suite&format=xml` request returned HTTP 200 with all 93 results. Both FitNesse and Perl processes were started by the controller and terminated after the complete response; the FitNesse trace records the controller's post-run SIGTERM and exit 143, not an in-test crash. The native test-system execution logs all report exit 0. Full logs and traces are retained under `/tmp/slim-native-audit/clean1` and `clean2`.

Both clean native runs selected the same paths in the same order with identical per-page counts. The root page-outcome bins were 70 right, 10 wrong, 1 ignored, and 12 exception-bearing results (93 page results total). Summing per-page assertions instead gives 525 right, 51 wrong, 4 ignored, and 321 exceptions. These are different measures: the root counts are outcome categories for page results, while the latter are assertion totals.

Backend attribution rests on several independent observations:

1. Each native suite XML execution-log entry used one of three test-system labels listed above, and all three logged `Connection to running SlimService` at the run's configured external listener address/port, exit status 0.
2. `strace -ff -e trace=process,network` of the FitNesse JVM recorded only the FitNesse JVM `execve`, no Java `SlimService` process launch, and SLiM connections to the configured external listener port.
3. Both external Perl server logs contain the suite's SLiM request/response traffic.
4. As a separate corroboration, each of the 93 selected pages was also run directly once with `?test`; all 93 page execution logs explicitly confirmed the external Perl listener. These individual direct results are useful for page attribution, but are not interchangeable with native-suite results because the suite shares context and generated wiki state.

The downloaded Java source used to verify selection was FitNesse tag `20251025`, specifically `SuiteResponder`, `SuiteContentsFinder`, and `SuiteFilter`. The source checkout and raw logs remain under `/tmp/slim-native-audit` and are not committed.

The suite root `SetUp` imports `fitnesse.fixtures` and loads `CustomTableAliasPlugin`, `CustomScriptTableRenderingPlugin`, and a `glob` custom comparator; nested pages include additional setup/library pages. `TestSystemSlimSuite` has a `Suites=SLIM` property, and the root suite has `Suites=slim, tag2`, but those tags did not filter this request. Test-system variation labels still connected to the same Perl listener. The suite root has no native `SuiteSetUp`/`SuiteTearDown` page. Several acceptance pages create nested `MySuite` pages through PageDriver. The clean native runs generated `MySuite.SuiteSetUp`, `SuiteTearDown`, `TearDown`, `TestPageA`, and `TestPageB`; the generated `SuiteSetUp` contains the intended StopTest constructor used by stop tests. Two earlier exploratory runs did not explicitly clear MySuite before startup and are excluded from the clean-run reproducibility claim: their page order matched, but four result rows changed in clean runs (two scenario stop pages, StopSuite, and StopTest).

## Native versus direct results

All 48 pages shared with the baseline produced the same assertion counts as their individual Perl baseline. Comparing the clean native suite to the additional per-page direct Perl runs, three native-only pages had different exception totals:

| Page | Native suite | Direct page run | Finding |
| --- | --- | --- | --- |
| `HybridDecisionTable` | 14 right, 46 exceptions | 14 right, 44 exceptions | Missing `Properties` fixture in both; suite context adds two exception results. |
| `HybridDecisionTable.MethodExtractorRuleTest` | 85 exceptions | 94 exceptions | Java method-extractor/configuration fixtures are unavailable in both runs. |
| `SystemExitIsPrevented` | 12 exceptions | 11 exceptions | JVM `System.exit` prevention is unsupported in this Java 25 / Perl environment. |

All other 90 page counts match between the clean suite results and direct isolated runs. `StopSuite`, `StopTest`, and the two scenario stop pages pass in the clean native run. The four wrong results observed for those pages in the earlier exploratory runs do not recur when generated MySuite state is removed before startup. This is why those initial results were excluded from the controlled-run reproducibility result.

No baseline page changed its conformance classification. In particular, all five established non-conformant pages have the same native and individual result counts:

| Page | Native and individual result | Existing explanation |
| --- | --- | --- |
| `CustomTableRenderingAddedByPluginTest` | 5 right, 1 wrong | Java reference passes 6/0. Perl PageDriver's nested HTTP request does not inherit the plugin/test context. |
| `IgnoredTestsShouldColorGray` | 5 right, 2 wrong | Java reference passes 7/0. Perl's nested HTTP request lacks the active FitNesse scenario context; the expected ignore markup is valid in v20251025. Stop/ignore protocol behavior itself is exercised. |
| `TestCustomComparators` | 1 right, 2 wrong | Java reference passes 3/0. Nested request does not inherit the configured custom comparator. |
| startup page B | 2 right, 1 wrong | Shared `manually.start.test.runner` configuration bypasses intended invalid child-runner startup. |
| startup page C | 3 right, 1 wrong | The expected-unused socket is occupied by the already running external Perl service. |

The two startup pages therefore remain harness/environment-limited, not evidence of Perl protocol defects. The native-suite request's configured service was intentionally running for the suite, so those pages could not recreate their no-server/invalid-child-server preconditions.

## Newly selected pages and scope

All 93 native-selected pages were directly executed against Perl one at a time, with the generated `MySuite` page cleared before each request. All 93 direct page responses confirmed a connection to external Perl. Of the 45 additional pages, **28 had zero wrong assertions and zero exceptions**; two further pages (`TestIgnoreAll` and `TestIgnoreInScriptTable`) each had four right assertions and one exception that is intentionally the SLiM ignore control marker. This identifies 30 additional pages with passing visible assertions for a Perl interoperability inventory. The expression page is a separately documented FitNesse table feature whose Java implementation relies on Nashorn and Java object semantics; it is not counted as a protocol test. The remaining 14 pages need Java-only behavior, fixture/adaptor support, or a controlled harness before they can be classified as protocol tests.

The important exception-heavy and wrong-heavy cases are classified as follows. Counts in the first column are from the native suite; parentheses give the isolated direct Perl result where it differs.

| Page | Native suite result (direct Perl result) | Scope finding |
| --- | --- | --- |
| `HybridDecisionTable` | 14 right, 46 exceptions (14 right, 44 exceptions) | Hybrid decision-table semantics are protocol-relevant, but the page imports Java fixtures and this run reports `Could not find class Properties`. The exception count is a fixture-availability failure; it does not isolate a protocol defect. A Perl `Properties` fixture/adapter would be needed before this page can validate the feature. |
| `HybridDecisionTable.MethodExtractorRuleTest` | 85 exceptions (94 exceptions) | Exercises Java `MethodExtractor`/configuration helper classes. Missing helpers prevent this from measuring general Perl SLiM interoperability. |
| `SlimSymbols.SlimSymbolsCanBeExpressionsToEvaluate` | 9 right, 21 wrong (same direct result) | FitNesse documents `$`expression`` table evaluation, but this behavior is not defined by the SLiM protocol. In v20251025 Java, `VariableStore` evaluates expression arguments with Nashorn and Java Map/List values; `SlimTable` separately evaluates expressions in client-side cells. Perl returns the 21 expression arguments unchanged. The result is a known difference in a documented FitNesse feature, not a defect in protocol instructions or ordinary `$NAME` substitution. The Java reference passes 30/30. Details and assertion-level results are in [`slim-symbol-expression-compatibility.md`](slim-symbol-expression-compatibility.md). |
| `SystemUnderTestTest` | 8 exceptions | Its `MySystemUnderTestDriver` fixture is Java-specific/unavailable in `t/lib`. The page does not demonstrate that the general Perl SUT-delegation implementation is wrong. |
| `TableTableSuite.SymbolsInTableTable` | 5 wrong, 4 exceptions | The page requests the ordinary `TableTableIncFirstCol` fixture under `fitnesse.slim.test`, which is absent. The related Perl fixture under `statementexecutorconsumer` explicitly manages symbol changes within a table; it is not a drop-in substitute for this page’s normal substitution and row-isolation behavior. The managed-fixture page passes 15 assertions; the Java v20251025 reference passes 13. |
| `TestExceptionIsDisplayed.ParameterConversionExceptions` | 14 wrong (same direct result) | The nested page expects Java converter/static method details (`java.time.Instant`, `String.valueOf`, Java primitive conversion text). Perl lacks those Java fixture classes and Java reflection behavior. This is not a fair default protocol-only conformance assertion. |
| `TestExceptionIsDisplayed.SlimExceptionResult` | 126 exceptions | Its target is FitNesse's Java `SlimExceptionResult` implementation. The page explicitly tests Java class behavior and cannot run as a Perl fixture test without that Java helper. Its nested errors are the behavior under examination, not 126 independent protocol defects. |
| `DefineTableTypeTest` | 6 exceptions | Requires `TableOrDecisionFixture`, an absent fixture. Table type handling is a candidate feature after adding the intended Perl fixture; current exceptions do not establish a protocol failure. |
| `DisgracerTest` | 22 exceptions | Calls FitNesse's Java `Disgracer` class. This is test-system name normalization, not behavior owned by the Perl SLiM server. |
| `SystemExitIsPrevented` | 12 exceptions | The upstream page itself says prevention of `System.exit` should be removed/pruned on Java 21 or later. It tests a JVM security/runtime feature unavailable in Perl, and Java 25 is installed here. |
| `TestSystemSlimSuite.JavaSlimServer.CallStaticJavaMethod` | 7 exceptions | Tests Java static method invocation (`java.time`/FitNesse utility methods), which is Java test-system functionality. The `Could not find class Instant::Parse` response is not a Perl SLiM protocol failure. |
| `TestIgnoreAll`, `TestIgnoreInScriptTable` | 4 right, 1 exception each | The upstream page explicitly raises an `ignore all` or `ignore` marker. The exception is the intended SLiM control response; both pages' assertions otherwise pass. Preserve as useful v0.5-ignore interoperability coverage. |

The direct results showed 40 of the 45 native-only pages with no wrong assertions, but that count includes pages with exceptions. The conservatively scoped set includes 28 pages with zero wrong assertions and zero exceptions plus 2 pages with intentional ignore-marker exceptions. Thus, 30 additional pages have passing visible results relevant to Perl interoperability. The expression page is tracked separately as a documented FitNesse feature with a Java-specific server-side implementation. The other 14 pages are Java-specific, fixture/adaptor-dependent, or require a controlled harness setup. Page-level applicability depends on whether a page targets the wire protocol, a fixture API, a Java helper, FitNesse rendering, or an environment precondition.

## The Java-reference expression run

To resolve whether expression failures were merely renderer markup differences, an isolated FitNesse v20251025 instance was run without `manually.start.test.runner=true`, with Java SLiM configured on a separate port. `strace` recorded FitNesse launching `java -cp /opt/fitnesse/fitnesse.jar fitnesse.slim.SlimService 18084`; the page execution log showed that process and exited 0. `SlimSymbolsCanBeExpressionsToEvaluate` produced 30 right, 0 wrong, 0 ignored, and 0 exceptions. This is positive Java-backend attribution. The source trace shows server-side `VariableStore` expression evaluation plus client-side `SlimTable` evaluation; it is not solely a client-side conversion issue. The direct Perl run produces 9 right, 21 wrong, 0 ignored, and 0 exceptions because it returns expression text unchanged. The 21 exact discrepancies and their symbol values are documented in [`slim-symbol-expression-compatibility.md`](slim-symbol-expression-compatibility.md). No evaluator was added: the reference delegates to Nashorn and exposes Java object behavior, while the protocol defines only named-symbol substitution. Any future support should be an explicit optional feature with a separately agreed grammar and conversion/error contract.

## Recommendation

Keep `bin/test-fitnesse` and the committed 45/50 classification as an independent mandatory Perl regression gate. It verifies all 50 individually selected pages against Perl, with zero regressions and zero server crashes. The native suite remains a separate test mode: it selects 93 pages, including 45 pages absent from the individual inventory and omitting two individual pages through pruning. It also mixes protocol checks with fixture, FitNesse client, and Java test-system behavior.

`bin/test-fitnesse-suite` now runs the complete native suite as a separate no-regression gate against [`fitnesse-slim-native-suite-baseline.json`](fitnesse-slim-native-suite-baseline.json). It starts from the wiki resources inside the pinned FitNesse JAR, verifies full page paths and exact per-page counts, and requires execution-log plus Perl request-trace evidence for the external backend. Every baseline row retains its applicability and expected-behavior classification; matching known Java fixture errors or Perl compatibility gaps does not convert them into conformant results. A baseline deviation is a failure pending review, never an automatic baseline update. The 50-page and 93-page gates run independently in CI. The former remains the direct compatibility scorecard; the latter protects the complete audited native selection and its current results.

The native runner writes its XML, per-page JSON comparison, and process logs under ignored `.runtime/`. For a reproducibility investigation, use a distinct `TEST_SLIM_SUITE_LOG_DIR` for each run, then compare sorted full page paths and all four per-page counts. Execution order is retained in the report as diagnostic data, not used as a substitute for path-and-count comparison. The runner uses the page result's full `pageHistoryLink`; the shorter `relativePageName` field contains only a leaf name for nested results.

Remaining uncertainty is limited to unreviewed native-only pages and whether a separately scoped, safe FitNesse expression compatibility component is desirable. This audit makes no claim of complete SLiM conformance. It makes no protocol code change and does not alter upstream expectations or the 45/50 baseline.

## Automated native-suite gate

`bin/test-fitnesse-suite` now protects this inventory independently of the 50-page `?test` runner. It extracts `Resources/FitNesseRoot` from the pinned v20251025 JAR into a temporary FitNesse home, so generated `MySuite` state from another run cannot affect selection. It starts FitNesse and the Perl server on isolated ports, points nested `PageDriver` requests at that same FitNesse instance, and removes the temporary wiki when done. This starts a FitNesse process only; no Java SLiM reference service is started.

The gate identifies every result by the full page path in its XML `pageHistoryLink`. It fails on missing, unexpected, or duplicate paths; any per-page change among right, wrong, ignored, or exception counts; changes to the suite final counts; malformed or incomplete XML; version drift; unverified test-system commands; missing Perl traffic; or unmatched Perl request/response logs. The baseline in [`fitnesse-slim-native-suite-baseline.json`](fitnesse-slim-native-suite-baseline.json) copies the 93 exact audited page results and their scope/behavior classifications from this audit. It is edited only through explicit review; the runner never regenerates it.

Two separately initialized runs against the extracted pinned-JAR wiki selected the same 93 full paths, in the same order, and produced identical page counts. Both matched the audited totals: 525 right, 51 wrong, 4 ignored, and 321 exceptions; FitNesse reported 70 right, 10 wrong, 1 ignored, and 12 exception page outcomes. Each run logged three FitNesse execution contexts connected to its runner-owned Perl port, and the Perl log contained 722 requests with 722 corresponding responses. The known wrong and exception results remain in the baseline with their existing classifications. A successful gate means only that the audited native selection and observations have not changed; it does not mean 93 pages conform to Perl.

CI keeps `bin/test-dev` and `bin/test-fitnesse` intact and runs this native gate as a separate step once per workflow. For local diagnosis, set a distinct `TEST_SLIM_SUITE_LOG_DIR` per run; each directory retains the suite XML, result JSON, FitNesse log, and Perl protocol log.

### Page-level classification notes

Three additional findings illustrate why raw exception totals are not enough:

- `ChainTest` is 3 right and 1 exception in a direct Perl run. The exact exception is `Method echo_boolean[1] not found in Fitnesse::Slim::Test::TestSlim`; the Perl test fixture has no `echo_boolean` method. This is a fixture coverage gap, not evidence of a frame or dispatch protocol defect.
- `TableTableSuite.TestReturnsNull` is 1 right and 2 exceptions. Its table is `fitnesse.slim.test.DummyTableTableReturnsNull`, which cannot load as the Perl `Fitnesse::Slim::Test::DummyTableTableReturnsNull` fixture. This is also fixture coverage.
- `TestSystemSlimSuite.ErrorSituationsDuringSlimServerStartup.A_TimeoutAsSlimHeaderNotReceived` and `ManualStartofSlimService` each return 2 right and 2 wrong. Their expected server startup/port conditions are not established when the same external Perl listener is already running on an alternate test port; they need a controlled harness configuration before interpreting those wrong checks.

The machine-readable record assigns every page a scope classification. For pages without a specific diagnosis, it deliberately says “review required” rather than attributing the result to the protocol. Passing a page directly is recorded as a candidate interoperability result, not as proof of broad protocol support.

## Complete native execution inventory
The JSON artifact stores all 93 fully qualified paths in native execution order and all 95 rows of the set union. Each row includes selection source, native-suite counts, isolated individual counts where measured, external backend evidence, expected-behavior assessment, and a detailed applicability note. The table uses short scope labels; detailed explanations for the notable pages are above. Counts are right/wrong/ignored/exceptions.

| Order | Full page path | Selection source | Native R/W/I/E | Direct Perl R/W/I/E | Scope |
|---:|---|---|---:|---:|---|
| 1 | `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.BaseLineDecisionTable` | Test property: true | 17/0/0/0 | 17/0/0/0 | Current 50-page baseline |
| 2 | `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.BaseLineDecisionTable.ComparatorsAreSupported` | Test property: true | 10/0/0/0 | 10/0/0/0 | Current 50-page baseline |
| 3 | `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.BaseLineDecisionTable.HowtoIgnoreResultValues` | Test property: empty/self-closing | 1/0/2/0 | 1/0/2/0 | Candidate direct Perl interoperability |
| 4 | `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.BaseLineDecisionTable.MakingTheBaselineTableTheDefaultDecisionTable` | Test property: true | 7/0/0/0 | 7/0/0/0 | Current 50-page baseline |
| 5 | `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.BaseLineDecisionTable.ScenariosAreSupported` | Test property: true | 10/0/0/0 | 10/0/0/0 | Current 50-page baseline |
| 6 | `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.BaseLineDecisionTable.TestFailuresAreMarked` | Test property: true | 8/0/0/0 | 8/0/0/0 | Current 50-page baseline |
| 7 | `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.ChainTest` | Test property: empty/self-closing | 3/0/0/1 | 3/0/0/1 | Perl fixture/adaptor coverage needed |
| 8 | `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.ChainWithInstanceTest` | Test property: true | 7/0/0/0 | 7/0/0/0 | Current 50-page baseline |
| 9 | `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.CustomTableRenderingAddedByPluginTest` | Test property: true | 5/1/0/0 | 5/1/0/0 | Current 50-page baseline |
| 10 | `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.DefineAliasInPluginTest` | Test property: true | 2/0/0/0 | 2/0/0/0 | Current 50-page baseline |
| 11 | `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.DefineAliasTest` | Test property: true | 22/0/0/0 | 22/0/0/0 | Current 50-page baseline |
| 12 | `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.DefineTableTypeTest` | Test property: empty/self-closing | 0/0/0/6 | 0/0/0/6 | Perl fixture/adaptor coverage needed |
| 13 | `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.DisgracerTest` | cross-reference/support page (no local Test marker observed) | 0/0/0/22 | 0/0/0/22 | Java fixture or test-system behavior |
| 14 | `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.ErikPragtBug` | Test property: empty/self-closing | 3/0/0/0 | 3/0/0/0 | Candidate direct Perl interoperability |
| 15 | `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.HashTableTests.HashTableWithHtmlContent` | Test property: true | 1/0/0/0 | 1/0/0/0 | Current 50-page baseline |
| 16 | `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.HashTableTests.ShouldConvertHashWidgetToHashTable` | Test property: empty/self-closing | 2/0/0/0 | 2/0/0/0 | Candidate direct Perl interoperability |
| 17 | `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.HashTableTests.ShouldReturnHashTable` | Test property: true | 1/0/0/0 | 1/0/0/0 | Current 50-page baseline |
| 18 | `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.HybridDecisionTable` | Test property: empty/self-closing | 14/0/0/46 | 14/0/0/44 | Perl fixture/adaptor coverage needed |
| 19 | `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.HybridDecisionTable.ImplementDynamicDecisionTableWithHybridTable` | Test property: true | 5/0/0/0 | 5/0/0/0 | Current 50-page baseline |
| 20 | `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.HybridDecisionTable.MethodExtractorRuleTest` | Test property: empty/self-closing | 0/0/0/85 | 0/0/0/94 | Java fixture or test-system behavior |
| 21 | `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.IgnoredTestsShouldColorGray` | Test property: true | 5/2/0/0 | 5/2/0/0 | Current 50-page baseline |
| 22 | `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.LibrarySuite.HowToAddFixturesWithParametersToTheLibrary` | Test property: true | 5/0/0/0 | 5/0/0/0 | Current 50-page baseline |
| 23 | `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.LibrarySuite.LastLibraryPreceedsEarlierLibraryTest` | Test property: true | 2/0/0/0 | 2/0/0/0 | Current 50-page baseline |
| 24 | `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.LibrarySuite.LibraryInSetUpSuite.LibraryInSetUpAndPageTest` | Test property: true | 2/0/0/0 | 2/0/0/0 | Current 50-page baseline |
| 25 | `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.LibrarySuite.LibraryInSetUpSuite.LibraryInSetUpTest` | Test property: true | 1/0/0/0 | 1/0/0/0 | Current 50-page baseline |
| 26 | `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.LibrarySuite.OneLibraryTest` | Test property: true | 1/0/0/0 | 1/0/0/0 | Current 50-page baseline |
| 27 | `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.MultiByteCharsInSlim` | Test property: empty/self-closing | 2/0/0/0 | 2/0/0/0 | Candidate direct Perl interoperability |
| 28 | `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.ParameterizedScenarios` | Test property: empty/self-closing | 15/0/0/0 | 15/0/0/0 | Candidate direct Perl interoperability |
| 29 | `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.QueryTableSuite.SetContextValue` | Test property: true | 4/0/2/0 | 4/0/2/0 | Current 50-page baseline |
| 30 | `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.QueryTableSuite.TestMatching` | Test property: true | 27/0/0/0 | 27/0/0/0 | Current 50-page baseline |
| 31 | `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.RegularExpressionMatching` | Test property: empty/self-closing | 4/0/0/0 | 4/0/0/0 | Candidate direct Perl interoperability |
| 32 | `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.ScenarioLibraryTestSuite.BlankCellsInNestedScenariosShouldWork` | Test property: empty/self-closing | 1/0/0/0 | 1/0/0/0 | Candidate direct Perl interoperability |
| 33 | `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.ScenarioLibraryTestSuite.BrotherScenarioLibraryIsIncluded` | Test property: empty/self-closing | 2/0/0/0 | 2/0/0/0 | Candidate direct Perl interoperability |
| 34 | `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.ScenarioLibraryTestSuite.NoScenarioSectionIfThereAreNone` | Test property: empty/self-closing | 2/0/0/0 | 2/0/0/0 | Candidate direct Perl interoperability |
| 35 | `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.ScenarioLibraryTestSuite.ScenarioLibrariesAreIncludedInTheCorrectOrder` | Test property: empty/self-closing | 5/0/0/0 | 5/0/0/0 | Candidate direct Perl interoperability |
| 36 | `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.ScenarioLibraryTestSuite.ScenarioLibrariesOnlyIncludedInTestPages` | Test property: empty/self-closing | 2/0/0/0 | 2/0/0/0 | Candidate direct Perl interoperability |
| 37 | `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.ScenarioLibraryTestSuite.ScenarioLibrariesOrderTests.ScenarioLibraryOrderSuite.ScenarioLibraryOrderTestParent.ScenarioLibraryOrderIsCorrect` | Test property: empty/self-closing | 3/0/0/0 | 3/0/0/0 | Candidate direct Perl interoperability |
| 38 | `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.ScenarioLibraryTestSuite.ScenarioLibraryShouldIncludeIncludedPages` | Test property: empty/self-closing | 0/0/0/0 | 0/0/0/0 | Candidate direct Perl interoperability |
| 39 | `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.ScenarioLibraryTestSuite.ScenariosOnlyInSlimTests` | Test property: empty/self-closing | 2/0/0/0 | 2/0/0/0 | Candidate direct Perl interoperability |
| 40 | `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.ScenarioLibraryTestSuite.ShouldBeAbleToDealWithPlaceholderScenarios` | Test property: empty/self-closing | 1/0/0/0 | 1/0/0/0 | Candidate direct Perl interoperability |
| 41 | `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.ScenarioTestSuite.ScenarioWithOutputParametersInDecisionTables` | Test property: true | 6/0/0/0 | 6/0/0/0 | Current 50-page baseline |
| 42 | `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.ScenarioTestSuite.ScenarioWithOutputParametersInScripts` | Test property: true | 4/0/0/0 | 4/0/0/0 | Current 50-page baseline |
| 43 | `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.ScenarioTestSuite.ScriptSubclassUsedForDecisionTable` | Test property: true | 2/0/0/0 | 2/0/0/0 | Current 50-page baseline |
| 44 | `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.ScenarioTestSuite.StopTestExceptionInDescisionTable` | legacy wiki Test header | 10/0/0/0 | 10/0/0/0 | Candidate direct Perl interoperability |
| 45 | `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.ScenarioTestSuite.UnknownOutputParameterInDescisionTable` | legacy wiki Test header | 5/0/0/0 | 5/0/0/0 | Candidate direct Perl interoperability |
| 46 | `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.ScenarioTestSuite.UsingConstructorArgumentsFromDecisionTablesInScenarios` | Test property: true | 8/0/0/0 | 8/0/0/0 | Current 50-page baseline |
| 47 | `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.SegregationOfRequirementsAndImplementation` | Test property: true | 12/0/0/0 | 12/0/0/0 | Current 50-page baseline |
| 48 | `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.SlimSymbols.NamingConvention` | Test property: true | 5/0/0/0 | 5/0/0/0 | Current 50-page baseline |
| 49 | `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.SlimSymbols.SlimSymbolCanHoldInstanceUsedAsParameter` | Test property: empty/self-closing | 8/0/0/0 | 8/0/0/0 | Candidate direct Perl interoperability |
| 50 | `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.SlimSymbols.SlimSymbolManipulation` | Test property: true | 18/0/0/0 | 18/0/0/0 | Current 50-page baseline |
| 51 | `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.SlimSymbols.SlimSymbolShouldShowRawContents` | Test property: empty/self-closing | 4/0/0/0 | 4/0/0/0 | Candidate direct Perl interoperability |
| 52 | `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.SlimSymbols.SlimSymbolsCanBeBlankOrNull` | Test property: empty/self-closing | 3/0/0/0 | 3/0/0/0 | Candidate direct Perl interoperability |
| 53 | `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.SlimSymbols.SlimSymbolsCanBeExpressionsToEvaluate` | legacy wiki Test header | 9/21/0/0 | 9/21/0/0 | Applicable: confirmed Perl interoperability gap |
| 54 | `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.SlimSymbols.SlimSymbolsWithSecretPrefixAreNotExpandedInHtml` | legacy wiki Test header | 3/0/0/0 | 3/0/0/0 | Candidate direct Perl interoperability |
| 55 | `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.SlimSymbols.TestCanPassSymbolsIntoConstructors` | Test property: empty/self-closing | 3/0/0/0 | 3/0/0/0 | Candidate direct Perl interoperability |
| 56 | `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.SlimSymbols.TestSymbolsDontGetTurnedToStringsInTheOutput` | Test property: empty/self-closing | 2/0/0/0 | 2/0/0/0 | Candidate direct Perl interoperability |
| 57 | `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.StopSuite` | Test property: true | 6/0/0/0 | 6/0/0/0 | Current 50-page baseline |
| 58 | `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.StopTest` | Test property: true | 6/0/0/0 | 6/0/0/0 | Current 50-page baseline |
| 59 | `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.StopTestInSuiteSetUp` | Test property: true | 7/0/0/0 | 7/0/0/0 | Current 50-page baseline |
| 60 | `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.SystemExitIsPrevented` | Test property: empty/self-closing | 0/0/0/12 | 0/0/0/11 | Java fixture or test-system behavior |
| 61 | `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.SystemUnderTestTest` | Test property: empty/self-closing | 0/0/0/8 | 0/0/0/8 | Java fixture or test-system behavior |
| 62 | `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.TableTableSuite.SymbolsInTableTable` | Test property: empty/self-closing | 0/5/0/4 | 0/5/0/4 | Historical audit result; ordinary fixture subsequently implemented |
| 63 | `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.TableTableSuite.SymbolsInTableTableManagedByTheFixture` | Test property: true | 15/0/0/0 | 15/0/0/0 | Current 50-page baseline |
| 64 | `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.TableTableSuite.TestReturnsNull` | Test property: empty/self-closing | 1/0/0/2 | 1/0/0/2 | Java fixture or test-system behavior |
| 65 | `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.TestChineseWords` | Test property: true | 1/0/0/0 | 1/0/0/0 | Current 50-page baseline |
| 66 | `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.TestComparators` | Test property: true | 26/0/0/0 | 26/0/0/0 | Current 50-page baseline |
| 67 | `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.TestCustomComparators` | Test property: true | 1/2/0/0 | 1/2/0/0 | Current 50-page baseline |
| 68 | `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.TestCustomConverter` | Test property: true | 13/0/0/0 | 13/0/0/0 | Current 50-page baseline |
| 69 | `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.TestDetailedDiff` | Test property: true | 22/0/0/0 | 22/0/0/0 | Current 50-page baseline |
| 70 | `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.TestExceptionCount` | Test property: empty/self-closing | 6/0/0/0 | 6/0/0/0 | Candidate direct Perl interoperability |
| 71 | `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.TestExceptionIsDisplayed` | Test property: true | 19/0/0/0 | 19/0/0/0 | Current 50-page baseline |
| 72 | `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.TestExceptionIsDisplayed.DisableExceptionTesting` | legacy wiki Test header | 2/0/0/0 | 2/0/0/0 | Candidate direct Perl interoperability |
| 73 | `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.TestExceptionIsDisplayed.ParameterConversionExceptions` | legacy wiki Test header | 3/14/0/0 | 3/14/0/0 | Java fixture or test-system behavior |
| 74 | `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.TestExceptionIsDisplayed.SlimExceptionResult` | legacy wiki Test header | 0/0/0/126 | 0/0/0/126 | Java fixture or test-system behavior |
| 75 | `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.TestHtmlContent` | Test property: empty/self-closing | 5/0/0/0 | 5/0/0/0 | Candidate direct Perl interoperability |
| 76 | `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.TestIgnoreAll` | cross-reference/support page (no local Test marker observed) | 4/0/0/1 | 4/0/0/1 | Applicable: intentional ignore marker |
| 77 | `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.TestIgnoreInScriptTable` | cross-reference/support page (no local Test marker observed) | 4/0/0/1 | 4/0/0/1 | Applicable: intentional ignore marker |
| 78 | `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.TestOrderedQueryWithDuplicateRows` | Test property: true | 14/0/0/0 | 14/0/0/0 | Current 50-page baseline |
| 79 | `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.TestPageWithInclude` | Test property: true | 1/0/0/0 | 1/0/0/0 | Current 50-page baseline |
| 80 | `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.TestScriptTable` | Test property: true | 2/0/0/0 | 2/0/0/0 | Current 50-page baseline |
| 81 | `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.TestScriptTableDisplayParameterValue` | Test property: true | 3/0/0/0 | 3/0/0/0 | Current 50-page baseline |
| 82 | `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.TestSequentialArgumentProcessing` | Test property: true | 8/0/0/0 | 8/0/0/0 | Current 50-page baseline |
| 83 | `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.TestSubsetQuery` | Test property: true | 11/0/0/0 | 11/0/0/0 | Current 50-page baseline |
| 84 | `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.TestSystemSlimSuite.JavaSlimServer.CallStaticJavaMethod` | legacy wiki Test header | 0/0/0/7 | 0/0/0/7 | Java fixture or test-system behavior |
| 85 | `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.TestSystemSlimSuite.ManualStartofSlimService` | legacy wiki Test header | 2/2/0/0 | 2/2/0/0 | Controlled harness configuration needed |
| 86 | `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.TestSystemSlimSuite.TimeoutInSlimTestSystem` | Test property: true | 4/0/0/0 | 4/0/0/0 | Current 50-page baseline |
| 87 | `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.TestTryingParameterizationIsntTooGreedy` | Test property: true | 1/0/0/0 | 1/0/0/0 | Current 50-page baseline |
| 88 | `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.TestTwoIdenticalTablesOnPageDontConflict` | Test property: true | 1/0/0/0 | 1/0/0/0 | Current 50-page baseline |
| 89 | `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.VariablesUsedInSubSubpage` | Test property: empty/self-closing | 22/0/0/0 | 22/0/0/0 | Candidate direct Perl interoperability |
| 90 | `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.TestSystemSlimSuite.ErrorSituationsDuringSlimServerStartup.A_TimeoutAsSlimHeaderNotReceived` | Test property: empty/self-closing | 2/2/0/0 | 2/2/0/0 | Controlled harness configuration needed |
| 91 | `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.TestSystemSlimSuite.ErrorSituationsDuringSlimServerStartup.B_TimeoutAsSlimServerDiesBeforeConnecting` | Test property: true | 2/1/0/0 | 2/1/0/0 | Current 50-page baseline |
| 92 | `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.TestSystemSlimSuite.ErrorSituationsDuringSlimServerStartup.C_TimeoutAsNoServerAtGivenSocket` | Test property: true | 3/1/0/0 | 3/1/0/0 | Current 50-page baseline |
| 93 | `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.TestSystemSlimSuite.TextBeforeSlimHeaderIsIgnored` | legacy wiki Test header | 2/0/0/0 | 2/0/0/0 | Candidate direct Perl interoperability |

## Subsequent Table Table fixture update

The original audit above records the 525/51/4/321 run. The dedicated ordinary fixture implementation later changed exactly one page: `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.TableTableSuite.SymbolsInTableTable` moved from 0/5/0/4 to 13/0/0/0. A clean pinned-JAR Java reference run also reports 13/0/0/0. The neighboring `SymbolsInTableTableManagedByTheFixture` page remains 15/0/0/0 in both Java and Perl.

The target execution log records the A/B/C assignments, `make TableTableIncFirstCol`, one `doTable` call with three symbol-bearing rows, and subsequent checks of 100, 6, and 15. Its included row-isolation case confirms Z=45 rather than 201. FitNesse applies output-symbol assignments after the table call returns. The Perl fixture has no row mutation; the consumer fixture continues to update symbols inside each row. A parent import from included page content masked the nested consumer fixture, so class lookup now tries more-specific imported package paths first.

The first native-suite run intentionally failed the old exact baseline comparison with only this page's three count changes. All other 92 pages remained identical. After review against the Java reference and both direct fixture tests, the baseline was changed only for this page. Updated assertion totals are 538 right, 46 wrong, 4 ignored, and 317 exceptions. FitNesse's suite final counts are 71 right, 9 wrong, 1 ignore, and 12 exceptions. A clean rerun selected all 93 pages, matched every per-page baseline count and these final counts, and verified 724 external Perl requests with 724 responses and no service errors. The separate 50-page individual acceptance gate remains unchanged.

## Subsequent null-return fixture update

`FitNesse.SuiteAcceptanceTests.SuiteSlimTests.TableTableSuite.TestReturnsNull` originally reported 1/0/0/2 in Perl because the named `DummyTableTableReturnsNull` fixture did not exist. The two errors were a failed construction (`Could not find class Fitnesse::Slim::Test::DummyTableTableReturnsNull`) and the following call on the absent instance (`The instance tableTable_42.doTable. does not exist`). The pinned Java fixture has a public no-argument constructor and `doTable(List<List<String>>)` that returns Java `null` for the whole table. Its SLiM instruction is `call tableTable_42 doTable [[]]`; FitNesse interprets the null table result as `ignore(No results from table)`. Both an isolated Java SlimService run and the external Perl run now report 1 right, 0 wrong, 1 ignored, and 0 exceptions.

The new Perl adapter returns `undef`. Existing statement execution and list serialization carry that value through the SLiM `null` representation; neither engine code nor protocol behavior changed. `t/null-table-fixture.t` exercises construction and invocation through serialized SLiM requests, null wire output, empty-string/list distinctions, missing-method errors, repeated calls, and session isolation. `t/import-resolution-precedence.t` now directly tests the executor's class resolution: longest imported package path first, later import on equal-length ties, and fallback past an absent class candidate.

The native runner first reported a baseline mismatch only on this target page; all other 92 page counts were unchanged. The reviewed entry now records 1/0/1/0. Aggregate assertion totals are 538 right, 46 wrong, 5 ignored, and 315 exceptions; FitNesse final counts are 72 right, 9 wrong, 1 ignored, and 11 exceptions. The 50-page individual baseline is unchanged.
