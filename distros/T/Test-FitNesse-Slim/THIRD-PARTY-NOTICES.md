# Third-party notices

## FitNesse-derived fixture adapters

These test-only Perl files are direct ports or adaptations of correspondingly
named fixtures in the FitNesse v20251025 source tree. They are included for
acceptance tests and are not installed as `Test::FitNesse::Slim` runtime modules. The
adapted fixture files are distributed under the FitNesse project's Common
Public License Version 1.0 (CPL 1.0), whose complete text is in
[`LICENSE.CPL`](LICENSE.CPL).

The Perl ports and adaptations listed below were contributed by Greg Bacon.

| Perl file | Upstream Java fixture |
| --- | --- |
| `t/lib/Fitnesse/Slim/Test/AddUpChange.pm` | `fitnesse.slim.test.AddUpChange` |
| `t/lib/Fitnesse/Slim/Test/ConstructorThrows.pm` | `fitnesse.slim.test.ConstructorThrows` |
| `t/lib/Fitnesse/Slim/Test/DecisionTableExecuteThrows.pm` | `fitnesse.slim.test.DecisionTableExecuteThrows` |
| `t/lib/Fitnesse/Slim/Test/DetailedDiff.pm` | `fitnesse.slim.test.DetailedDiff` |
| `t/lib/Fitnesse/Slim/Test/EchoScript.pm` | `fitnesse.slim.test.EchoScript` |
| `t/lib/Fitnesse/Slim/Test/Library/EchoSupport.pm` | `fitnesse.slim.test.library.EchoSupport` |
| `t/lib/Fitnesse/Slim/Test/Library/LibraryInSetUp.pm` | `fitnesse.slim.test.library.LibraryInSetUp` |
| `t/lib/Fitnesse/Slim/Test/Library/SpecialEchoSupport.pm` | `fitnesse.slim.test.library.SpecialEchoSupport` |
| `t/lib/Fitnesse/Slim/Test/LoginDialogDriver.pm` | `fitnesse.slim.test.LoginDialogDriver` |
| `t/lib/Fitnesse/Slim/Test/ShouldIBuyMilk.pm` | `fitnesse.slim.test.ShouldIBuyMilk` |
| `t/lib/Fitnesse/Slim/Test/Sleep.pm` | `fitnesse.slim.test.Sleep` |
| `t/lib/Fitnesse/Slim/Test/Statementexecutorconsumer/TableTableIncFirstCol.pm` | `fitnesse.slim.test.statementexecutorconsumer.TableTableIncFirstCol` |
| `t/lib/Fitnesse/Slim/Test/TableResultExtractor.pm` | `fitnesse.slim.test.TableResultExtractor` |
| `t/lib/Fitnesse/Slim/Test/TableTableIncFirstCol.pm` | `fitnesse.slim.test.TableTableIncFirstCol` |
| `t/lib/Fitnesse/Slim/Test/TestQuery.pm` | `fitnesse.slim.test.TestQuery` |
| `t/lib/Fitnesse/Slim/Test/TestSlim.pm` | `fitnesse.slim.test.TestSlim` |
| `t/lib/Fitnesse/Slim/Test/TestSlimWithConverter.pm` | `fitnesse.slim.test.TestSlimWithConverter` |

FitNesse v20251025 source is available at
[the tagged fixture tree](https://github.com/unclebob/fitnesse/tree/v20251025/src/fitnesse/slim/test)
and declares the project license in its
[CPL 1.0 license file](https://github.com/unclebob/fitnesse/blob/v20251025/LICENSE.txt).
The upstream Java files for `DecisionTableExecuteThrows`, `EchoScript`,
`LoginDialogDriver`, `ShouldIBuyMilk`, `TestQuery`, `TestSlim`, and three
library fixtures carry an explicit Object Mentor copyright and CPL notice;
the corresponding Perl files retain that attribution. The remaining mapped
fixtures have no per-file copyright header in the upstream source, but their
fixture-specific code is adapted from that CPL-licensed source tree and is
kept under CPL for distribution.

Three source counterparts have only trivial behavior in these Perl versions:
`DummyTableTableReturnsNull.pm` returns no value, `NullFixture.pm` returns null
or an empty string, and `LibraryFixture.pm` is an empty fixture shell. Their
local implementations contain no substantial upstream expression, so this
notice does not classify them as CPL-derived. This is a source-expression
assessment; a broader legal determination of derivative-work status remains
outside this audit.

The `lib/Test/FitNesse/Slim/` implementation is independently written Perl based on
the SLiM protocol and observed FitNesse behavior; it is not a translation of
FitNesse Java implementation code. The repository's Perl regression tests,
acceptance harness, order-management example, and other test fixtures are
independently written and are not included in this CPL list. The local pinned
FitNesse JAR and upstream acceptance wiki are excluded from the distribution.

This file-level split is the basis for the mixed-license CPAN metadata. The
metadata and this notice identify scope, but do not by themselves resolve any
legal compatibility question about distributing the combined archive.
