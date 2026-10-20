# FitNesse acceptance coverage comparison

Generated from the two committed baselines and the audited FitNesse v20251025 selection. The isolated and native modes remain separate gates.

| Inventory | Pages |
|---|---:|
| Individually executed | 50 |
| Native suite selected | 93 |
| Shared | 48 |
| Individual only | 2 |
| Native only | 45 |
| Union | 95 |

## Why the inventories differ

The individual runner is a deliberate 50-page regression inventory. It clears generated `MySuite` pages between requests and checks each selected page in isolation. The native runner delegates traversal to FitNesse's suite responder, which includes enabled empty `Test` properties, legacy test headers, and referenced support pages. It also preserves suite execution context and ordering.

No filter tags were supplied; `Suites` properties did not constrain this suite selection. Seven property-marked pages are excluded by their own or an ancestor's `Prune` property. Selection source counts: Test=true property: 48, cross-reference/support page: 3, empty Test property: 32, legacy Test header: 10.

## Independent regression evidence

| Dimension | Isolated pages | Native suite |
|---|---|---|
| Page lifecycle | One HTTP test per selected page; generated `MySuite` is cleared between requests. | FitNesse traverses and executes the complete selected suite in order, retaining shared suite context. |
| Discovery | Deliberate 50-page regression list with explicit Test properties. | FitNesse v20251025 suite traversal, including empty Test properties, legacy headers, references, and pruning. |
| Primary evidence | Stable direct page results and page-level cleanup. | Suite setup/inheritance/order and exact native discovery. |
| Transport | Pipe launches Perl as a FitNesse child; TCP checks a real external listener. | Same two transports with separate exact tuple expectations. |

## Scenario library discrepancy

`FitNesse.SuiteAcceptanceTests.SuiteSlimTests.ScenarioLibraryTestSuite.ScenariosOnlyInSlimTests` is native-suite-only; it is not one of the current 50 selected individual pages. The earlier direct-page audit and TCP native baseline both recorded 2/0/0/0 (R/W/I/E) and the corrected pipe native run records 2/0/0/0. The root cause was: configure_pipe_wiki appended !define TEST_SYSTEM {slim} at wiki root, forcing generated MySuite.TestPage into Slim test selection. Pipe setup now adds only runner, command-pattern, and port defaults; TEST_SYSTEM remains page-local. Pipe and TCP native results match at 2 right and 0 wrong.

## Historical direct-run versus native-suite differences

The audit also ran all 93 selected pages individually as a separate exploratory comparison. Three native-only pages had different direct and suite tuples; those direct runs are not the current 50-page regression inventory and are preserved here as separate context evidence.

- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.HybridDecisionTable` — direct 14/0/0/44, native suite 14/0/0/46 (R/W/I/E). The audited direct and suite runs produced different assertion tuples; this is retained as an observed mode-specific baseline difference.
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.HybridDecisionTable.MethodExtractorRuleTest` — direct 0/0/0/94, native suite 0/0/0/85 (R/W/I/E). The audited direct and suite runs produced different assertion tuples; this is retained as an observed mode-specific baseline difference.
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.SystemExitIsPrevented` — direct 0/0/0/11, native suite 0/0/0/12 (R/W/I/E). The audited direct and suite runs produced different assertion tuples; this is retained as an observed mode-specific baseline difference.

## Pages in both inventories

- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.BaseLineDecisionTable`
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.BaseLineDecisionTable.ComparatorsAreSupported`
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.BaseLineDecisionTable.MakingTheBaselineTableTheDefaultDecisionTable`
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.BaseLineDecisionTable.ScenariosAreSupported`
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.BaseLineDecisionTable.TestFailuresAreMarked`
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.ChainWithInstanceTest`
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.CustomTableRenderingAddedByPluginTest`
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.DefineAliasInPluginTest`
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.DefineAliasTest`
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.HashTableTests.HashTableWithHtmlContent`
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.HashTableTests.ShouldReturnHashTable`
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.HybridDecisionTable.ImplementDynamicDecisionTableWithHybridTable`
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.IgnoredTestsShouldColorGray`
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.LibrarySuite.HowToAddFixturesWithParametersToTheLibrary`
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.LibrarySuite.LastLibraryPreceedsEarlierLibraryTest`
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.LibrarySuite.LibraryInSetUpSuite.LibraryInSetUpAndPageTest`
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.LibrarySuite.LibraryInSetUpSuite.LibraryInSetUpTest`
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.LibrarySuite.OneLibraryTest`
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.QueryTableSuite.SetContextValue`
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.QueryTableSuite.TestMatching`
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.ScenarioTestSuite.ScenarioWithOutputParametersInDecisionTables`
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.ScenarioTestSuite.ScenarioWithOutputParametersInScripts`
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.ScenarioTestSuite.ScriptSubclassUsedForDecisionTable`
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.ScenarioTestSuite.UsingConstructorArgumentsFromDecisionTablesInScenarios`
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.SegregationOfRequirementsAndImplementation`
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.SlimSymbols.NamingConvention`
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.SlimSymbols.SlimSymbolManipulation`
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.StopSuite`
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.StopTest`
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.StopTestInSuiteSetUp`
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.TableTableSuite.SymbolsInTableTableManagedByTheFixture`
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.TestChineseWords`
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.TestComparators`
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.TestCustomComparators`
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.TestCustomConverter`
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.TestDetailedDiff`
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.TestExceptionIsDisplayed`
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.TestOrderedQueryWithDuplicateRows`
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.TestPageWithInclude`
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.TestScriptTable`
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.TestScriptTableDisplayParameterValue`
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.TestSequentialArgumentProcessing`
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.TestSubsetQuery`
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.TestSystemSlimSuite.ErrorSituationsDuringSlimServerStartup.B_TimeoutAsSlimServerDiesBeforeConnecting`
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.TestSystemSlimSuite.ErrorSituationsDuringSlimServerStartup.C_TimeoutAsNoServerAtGivenSocket`
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.TestSystemSlimSuite.TimeoutInSlimTestSystem`
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.TestTryingParameterizationIsntTooGreedy`
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.TestTwoIdenticalTablesOnPageDontConflict`

## Individual inventory only

- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.TestSystemSlimSuite.HowtoEnforceA_TimelimitPerTestCommand.NotWorking_SettingSlimTimeout` — Both pages are Test=true but their parent Suite has <Prune/>..
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.TestSystemSlimSuite.HowtoEnforceA_TimelimitPerTestCommand.PartiallyWorking_SettingSlimFlags` — Both pages are Test=true but their parent Suite has <Prune/>..

## Native suite only

- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.BaseLineDecisionTable.HowtoIgnoreResultValues` — Test property: empty/self-closing.
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.ChainTest` — Test property: empty/self-closing.
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.DefineTableTypeTest` — Test property: empty/self-closing.
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.DisgracerTest` — cross-reference/support page (no local Test marker observed).
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.ErikPragtBug` — Test property: empty/self-closing.
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.HashTableTests.ShouldConvertHashWidgetToHashTable` — Test property: empty/self-closing.
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.HybridDecisionTable` — Test property: empty/self-closing.
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.HybridDecisionTable.MethodExtractorRuleTest` — Test property: empty/self-closing.
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.MultiByteCharsInSlim` — Test property: empty/self-closing.
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.ParameterizedScenarios` — Test property: empty/self-closing.
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.RegularExpressionMatching` — Test property: empty/self-closing.
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.ScenarioLibraryTestSuite.BlankCellsInNestedScenariosShouldWork` — Test property: empty/self-closing.
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.ScenarioLibraryTestSuite.BrotherScenarioLibraryIsIncluded` — Test property: empty/self-closing.
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.ScenarioLibraryTestSuite.NoScenarioSectionIfThereAreNone` — Test property: empty/self-closing.
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.ScenarioLibraryTestSuite.ScenarioLibrariesAreIncludedInTheCorrectOrder` — Test property: empty/self-closing.
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.ScenarioLibraryTestSuite.ScenarioLibrariesOnlyIncludedInTestPages` — Test property: empty/self-closing.
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.ScenarioLibraryTestSuite.ScenarioLibrariesOrderTests.ScenarioLibraryOrderSuite.ScenarioLibraryOrderTestParent.ScenarioLibraryOrderIsCorrect` — Test property: empty/self-closing.
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.ScenarioLibraryTestSuite.ScenarioLibraryShouldIncludeIncludedPages` — Test property: empty/self-closing.
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.ScenarioLibraryTestSuite.ScenariosOnlyInSlimTests` — Test property: empty/self-closing.
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.ScenarioLibraryTestSuite.ShouldBeAbleToDealWithPlaceholderScenarios` — Test property: empty/self-closing.
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.ScenarioTestSuite.StopTestExceptionInDescisionTable` — legacy wiki Test header.
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.ScenarioTestSuite.UnknownOutputParameterInDescisionTable` — legacy wiki Test header.
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.SlimSymbols.SlimSymbolCanHoldInstanceUsedAsParameter` — Test property: empty/self-closing.
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.SlimSymbols.SlimSymbolShouldShowRawContents` — Test property: empty/self-closing.
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.SlimSymbols.SlimSymbolsCanBeBlankOrNull` — Test property: empty/self-closing.
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.SlimSymbols.SlimSymbolsCanBeExpressionsToEvaluate` — legacy wiki Test header.
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.SlimSymbols.SlimSymbolsWithSecretPrefixAreNotExpandedInHtml` — legacy wiki Test header.
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.SlimSymbols.TestCanPassSymbolsIntoConstructors` — Test property: empty/self-closing.
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.SlimSymbols.TestSymbolsDontGetTurnedToStringsInTheOutput` — Test property: empty/self-closing.
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.SystemExitIsPrevented` — Test property: empty/self-closing.
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.SystemUnderTestTest` — Test property: empty/self-closing.
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.TableTableSuite.SymbolsInTableTable` — Test property: empty/self-closing.
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.TableTableSuite.TestReturnsNull` — Test property: empty/self-closing.
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.TestExceptionCount` — Test property: empty/self-closing.
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.TestExceptionIsDisplayed.DisableExceptionTesting` — legacy wiki Test header.
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.TestExceptionIsDisplayed.ParameterConversionExceptions` — legacy wiki Test header.
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.TestExceptionIsDisplayed.SlimExceptionResult` — legacy wiki Test header.
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.TestHtmlContent` — Test property: empty/self-closing.
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.TestIgnoreAll` — cross-reference/support page (no local Test marker observed).
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.TestIgnoreInScriptTable` — cross-reference/support page (no local Test marker observed).
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.TestSystemSlimSuite.ErrorSituationsDuringSlimServerStartup.A_TimeoutAsSlimHeaderNotReceived` — Test property: empty/self-closing.
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.TestSystemSlimSuite.JavaSlimServer.CallStaticJavaMethod` — legacy wiki Test header.
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.TestSystemSlimSuite.ManualStartofSlimService` — legacy wiki Test header.
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.TestSystemSlimSuite.TextBeforeSlimHeaderIsIgnored` — legacy wiki Test header.
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.VariablesUsedInSubSubpage` — Test property: empty/self-closing.

## Property-marked pages pruned from native traversal

- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.BaseLineDecisionTable.TestFailuresAreMarked.TestPage` — empty Test property; `Prune` is set on `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.BaseLineDecisionTable.TestFailuresAreMarked.TestPage`.
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.IgnoredTestsShouldColorGray.TestPage` — empty Test property; `Prune` is set on `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.IgnoredTestsShouldColorGray.TestPage`.
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.ScenarioLibraryTestSuite.ScenarioLibraryShouldIncludeVariables` — empty Test property; `Prune` is set on `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.ScenarioLibraryTestSuite.ScenarioLibraryShouldIncludeVariables`.
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.TableTableSuite.SymbolAssignmentAndReferenceOfTheSameInOneTable` — empty Test property; `Prune` is set on `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.TableTableSuite.SymbolAssignmentAndReferenceOfTheSameInOneTable`.
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.TestDetailedDiff.TestPage` — empty Test property; `Prune` is set on `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.TestDetailedDiff.TestPage`.
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.TestSystemSlimSuite.HowtoEnforceA_TimelimitPerTestCommand.NotWorking_SettingSlimTimeout` — true Test property; `Prune` is set on `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.TestSystemSlimSuite.HowtoEnforceA_TimelimitPerTestCommand`.
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.TestSystemSlimSuite.HowtoEnforceA_TimelimitPerTestCommand.PartiallyWorking_SettingSlimFlags` — true Test property; `Prune` is set on `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.TestSystemSlimSuite.HowtoEnforceA_TimelimitPerTestCommand`.

See [the JSON manifest](fitnesse-acceptance-coverage.json) for every page's membership, result tuple, selection evidence, and discovery metadata.

## Other wiki pages outside native results

The pinned subtree contains 136 page records stored as `content.txt` directories or legacy `.wiki` files; 43 did not produce native suite result rows.

- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests` — no enabled Test property or reference selected this page.
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.BaseLineDecisionTable.MakingTheBaselineTableTheDefaultDecisionTable.TearDown` — no enabled Test property or reference selected this page.
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.BaseLineDecisionTable.TestFailuresAreMarked.TestPage` — excluded by Prune at FitNesse.SuiteAcceptanceTests.SuiteSlimTests.BaseLineDecisionTable.TestFailuresAreMarked.TestPage.
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.HashTableTests` — no enabled Test property or reference selected this page.
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.HybridDecisionTable.SetUp` — no enabled Test property or reference selected this page.
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.HybridDecisionTable.TearDown` — no enabled Test property or reference selected this page.
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.IgnoredTestsShouldColorGray.TestPage` — excluded by Prune at FitNesse.SuiteAcceptanceTests.SuiteSlimTests.IgnoredTestsShouldColorGray.TestPage.
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.LibrarySuite` — no enabled Test property or reference selected this page.
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.LibrarySuite.LibraryInSetUpSuite` — no enabled Test property or reference selected this page.
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.LibrarySuite.LibraryInSetUpSuite.SetUp` — no enabled Test property or reference selected this page.
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.LibrarySuite.ScenarioLibrary` — no enabled Test property or reference selected this page.
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.LibrarySuite.SetUp` — no enabled Test property or reference selected this page.
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.QueryTableSuite` — no enabled Test property or reference selected this page.
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.ScenarioLibraryTestSuite` — no enabled Test property or reference selected this page.
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.ScenarioLibraryTestSuite.DoesntFailIfScenariosIncludedTwice` — no enabled Test property or reference selected this page.
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.ScenarioLibraryTestSuite.ScenarioLibrariesOrderTests` — no enabled Test property or reference selected this page.
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.ScenarioLibraryTestSuite.ScenarioLibrariesOrderTests.ScenarioLibrary` — no enabled Test property or reference selected this page.
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.ScenarioLibraryTestSuite.ScenarioLibrariesOrderTests.ScenarioLibraryOrderSuite` — no enabled Test property or reference selected this page.
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.ScenarioLibraryTestSuite.ScenarioLibrariesOrderTests.ScenarioLibraryOrderSuite.ScenarioLibrary` — no enabled Test property or reference selected this page.
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.ScenarioLibraryTestSuite.ScenarioLibrariesOrderTests.ScenarioLibraryOrderSuite.ScenarioLibraryOrderTestParent` — no enabled Test property or reference selected this page.
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.ScenarioLibraryTestSuite.ScenarioLibrariesOrderTests.ScenarioLibraryOrderSuite.ScenarioLibraryOrderTestParent.ScenarioLibrary` — no enabled Test property or reference selected this page.
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.ScenarioLibraryTestSuite.ScenarioLibraryShouldIncludeIncludedPages.ScenarioLibrary` — no enabled Test property or reference selected this page.
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.ScenarioLibraryTestSuite.ScenarioLibraryShouldIncludeIncludedPages.ScenarioLibrary.IncludedPage` — no enabled Test property or reference selected this page.
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.ScenarioLibraryTestSuite.ScenarioLibraryShouldIncludeVariables` — excluded by Prune at FitNesse.SuiteAcceptanceTests.SuiteSlimTests.ScenarioLibraryTestSuite.ScenarioLibraryShouldIncludeVariables.
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.ScenarioTestSuite` — no enabled Test property or reference selected this page.
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.SegregationOfRequirementsAndImplementation.CalculatorRequirements` — no enabled Test property or reference selected this page.
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.SetUp` — no enabled Test property or reference selected this page.
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.SlimSymbols` — no enabled Test property or reference selected this page.
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.SuiteSpecificationsPage` — no enabled Test property or reference selected this page.
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.TableTableSuite` — no enabled Test property or reference selected this page.
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.TableTableSuite.SymbolAssignmentAndReferenceOfTheSameInOneTable` — excluded by Prune at FitNesse.SuiteAcceptanceTests.SuiteSlimTests.TableTableSuite.SymbolAssignmentAndReferenceOfTheSameInOneTable.
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.TestDetailedDiff.TestPage` — excluded by Prune at FitNesse.SuiteAcceptanceTests.SuiteSlimTests.TestDetailedDiff.TestPage.
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.TestExceptionIsDisplayed.ParameterConversionExceptions.TestPage` — no enabled Test property or reference selected this page.
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.TestExceptionIsDisplayed.TestPage` — no enabled Test property or reference selected this page.
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.TestPageWithInclude.IncludedPage` — no enabled Test property or reference selected this page.
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.TestSystemSlimSuite` — no enabled Test property or reference selected this page.
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.TestSystemSlimSuite.ErrorSituationsDuringSlimServerStartup` — no enabled Test property or reference selected this page.
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.TestSystemSlimSuite.HowtoEnforceA_TimelimitPerTestCommand` — no enabled Test property or reference selected this page.
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.TestSystemSlimSuite.HowtoEnforceA_TimelimitPerTestCommand.NotWorking_SettingSlimTimeout` — excluded by Prune at FitNesse.SuiteAcceptanceTests.SuiteSlimTests.TestSystemSlimSuite.HowtoEnforceA_TimelimitPerTestCommand.
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.TestSystemSlimSuite.HowtoEnforceA_TimelimitPerTestCommand.PartiallyWorking_SettingSlimFlags` — excluded by Prune at FitNesse.SuiteAcceptanceTests.SuiteSlimTests.TestSystemSlimSuite.HowtoEnforceA_TimelimitPerTestCommand.
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.TestSystemSlimSuite.JavaSlimServer` — no enabled Test property or reference selected this page.
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.VariablesUsedInSubSubpage.TestWithVariable` — no enabled Test property or reference selected this page.
- `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.VariablesUsedInSubSubpage.VariablesRedefinedMultipleTimesOnSamePageAndUsedInSubpage` — no enabled Test property or reference selected this page.
