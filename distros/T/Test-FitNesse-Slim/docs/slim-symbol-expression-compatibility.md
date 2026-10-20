# SLiM table-expression compatibility

## Finding

The page
`FitNesse.SuiteAcceptanceTests.SuiteSlimTests.SlimSymbols.SlimSymbolsCanBeExpressionsToEvaluate`
tests FitNesse's documented *Expressions in Tables* feature. It does not test a
SLiM wire instruction or the protocol's named-symbol substitution rule. The
SLiM protocol specification describes instructions as lists of strings and
defines replacement of `$NAME` references; it does not define the backtick
expression form ``$`expression` ``. FitNesse's separate table-expression guide
does document expression evaluation as a FitNesse table feature.

In v20251025, Java implements this feature in both the server-side
`VariableStore` and FitNesse's `SlimTable`. Both use `SlimExpressionEvaluator`,
which runs expressions through Nashorn's JavaScript `ScriptEngine`. Before
evaluation it converts the serialized hash/list values to Java `Map` and
`List` objects. This supplies JavaScript operators alongside Java methods and
Java object behavior such as `Map.size()` and `Object.getClass()`. Evaluation
errors become strings beginning `Unable to evaluate: ...`.

The Perl executor recognizes ordinary `$NAME` references and preserves exact
symbol values and object identity. It does not parse ``$`expression` ``. In the
external-Perl reproduction, `echo` therefore received each backtick expression
as ordinary text and returned it unchanged. This is why simple arithmetic
expressions fail too: the Perl service does not evaluate them at all.

## Execution trace and compatibility boundary

For expression arguments, FitNesse sends the backtick text in a normal SLiM
`call` argument. Java's `VariableStore.getStored` recognizes the ``$`...` `` form,
loads symbol objects, converts serialized hashes and lists, and asks
`SlimExpressionEvaluator` to evaluate the expression. The result then follows
normal fixture result conversion and serialization. The Perl server follows
the ordinary `$NAME` path only; it passes the expression text to the fixture.

For expressions in expected or other client-side cells, `SlimTable` uses the
same evaluator with symbols from its test context. This is FitNesse-side table
processing and is independent of Perl fixture execution.

The appropriate boundary is an **optional, separately scoped compatibility
component**, not the SLiM protocol core and not a fixture. The feature is
documented by FitNesse but its expression language and Java object model are
not specified by the protocol. The Java reference delegates to a script engine
without a narrow grammar, and this page relies on Java methods, Java collection
types, and Java class names. An unrestricted Perl `eval` would execute arbitrary
code and still would not provide Java semantics. A small arithmetic-only
parser would not implement the feature this page specifies. No evaluator is
added to the default Perl service. If cross-backend table-expression support
is later required, it should be an explicit opt-in component with an agreed
grammar, type model, and error contract; until then this remains a known
FitNesse/Java-specific compatibility difference.

## Assertion-level comparison

The full upstream page was run against the external Perl listener on 2026-10-16.
Its XML result was 9 right, 21 wrong, 0 ignored, and 0 exceptions. The Perl log
contains the corresponding command and response traffic. The Java reference
run recorded in the native-suite audit used the installed v20251025 Java
`SlimService` and returned 30 right, 0 wrong, 0 ignored, and 0 exceptions.

In the table below, “Perl actual” is the exact argument text returned by the
`echo` fixture. In all 21 cases, Java evaluates the expression before calling
`echo`; Perl preserves the text. The expressions themselves are not wire-level
operations.

| # | Expression sent as argument | Relevant symbols | Java result / page expectation | Perl actual |
|---:|---|---|---|---|
| 1 | ``$`myHashMap0.key1` `` | `myHashMap0`: map from `hash` fixture | `value1` | ``$`myHashMap0.key1` `` |
| 2 | ``$`myHashMap0.key2.subkey` `` | `myHashMap0`: nested map | `subval` | ``$`myHashMap0.key2.subkey` `` |
| 3 | ``$`myHashMap0.key3` `` | `myHashMap0`; absent key | `null` | ``$`myHashMap0.key3` `` |
| 4 | ``$`myHashMap.key1` `` | `myHashMap`: second `hash` fixture map | `value2` | ``$`myHashMap.key1` `` |
| 5 | ``$`myHashMap.key2.subkey` `` | `myHashMap`: nested map | `subval2` | ``$`myHashMap.key2.subkey` `` |
| 6 | ``$`myHashMap.key3` `` | `myHashMap`; absent key | `null` | ``$`myHashMap.key3` `` |
| 7 | ``$`myHashMap3.key1` `` | `myHashMap3` is unbound | Error string matching `Unable to evaluate: myHashMap3.key1; .+` | ``$`myHashMap3.key1` `` |
| 8 | ``$`myHashMap2.key1` `` | `myHashMap2`: string/hash-widget output from `echo` | `value2` | ``$`myHashMap2.key1` `` |
| 9 | ``$`myHashMap2.key2.subkey` `` | `myHashMap2`: nested string/hash-widget output | `subval1` | ``$`myHashMap2.key2.subkey` `` |
| 10 | ``$`10+20` `` | None | `30` | ``$`10+20` `` |
| 11 | ``$`myHashMap.size() * 1.5` `` | `myHashMap`: Java `Map` | `3.0` | ``$`myHashMap.size() * 1.5` `` |
| 12 | ``$`myStr.toUpperCase()` `` | `myStr`: `This is a test` | `THIS IS A TEST` | ``$`myStr.toUpperCase()` `` |
| 13 | ``$`myStr.substr(2,5)` `` | `myStr`: `This is a test` | `is is` | ``$`myStr.substr(2,5)` `` |
| 14 | ``$`1+1` a `` | None | `2 a` | ``$`1+1` a `` |
| 15 | ``$`1+1`a `` | None | `2a` | ``$`1+1`a `` |
| 16 | ``a$`1+1`a `` | None | `a2a` | ``a$`1+1`a `` |
| 17 | ``$`myList.size()` `` | `myList`: standard Java `ArrayList` result | `3` | ``$`myList.size()` `` |
| 18 | ``$`myList.getClass()` `` | `myList`: standard Java `ArrayList` result | `class java.util.ArrayList` | ``$`myList.getClass()` `` |
| 19 | ``$`myList.getClass()` `` | Same as #18; expected cell also evaluates this expression | `class java.util.ArrayList` | ``$`myList.getClass()` `` |
| 20 | ``$`myList2.size()` `` | `myList2`: `ArrayList` from custom list converter | `3` | ``$`myList2.size()` `` |
| 21 | ``$`myList2.getClass()` `` | `myList2`: `ArrayList` from custom list converter | `class java.util.ArrayList` | ``$`myList2.getClass()` `` |

### Causes

* **Map access and conversion (1–9):** the Java evaluator turns map-shaped
  values into Java maps, including nested values, and turns absent members into
  JavaScript `undefined`/`null`-like results. Missing symbol evaluation is
  reported as an evaluator error. Perl correctly handles the underlying hash
  fixture and serialized hash values, but does not evaluate member expressions.
* **Operators and strings (10–16):** JavaScript arithmetic, multiplication,
  string method calls, and concatenation run in Nashorn. These operations look
  portable in isolation, but the syntax and coercion rules are those of the
  JavaScript engine. They are not `$NAME` substitution.
* **Lists and Java type inspection (17–21):** the Java evaluator converts list
  results to Java `ArrayList` values and supports Java methods and class
  identity. Reproducing `getClass()` is inherently tied to the Java runtime and
  converter configuration.

The arithmetic and string cases could be approximated by a safe parser, but the
page's complete behavior cannot be represented by that subset. The map/list
cases also require consistent object conversion and JavaScript/Java method
semantics. No assertion was removed or reclassified as passing.

## Verification and remaining limitations

The live Perl page reproduction returned 9/21, matching the audited native
baseline exactly. The page is not part of the 50-page individual baseline; its
known 9/21 result remains in the independent 93-page native-suite baseline.
This classification change does not alter its expected counts, the 50-page
45/50 conformance score, or the full native-suite result oracle.

The Perl symbol unit tests cover ordinary exact and embedded substitutions,
null values, missing names, reference identity, and nested list symbols. They
do not claim backtick-expression compatibility. There is no Perl expression
engine, parser, or expression-specific regression suite because no expression
semantics were added. The focused evidence is the unchanged upstream page run
and the Java implementation trace above.

Sources:

* [SLiM protocol specification](https://fitnesse.org/FitNesse.UserGuide.WritingAcceptanceTests.SliM.SlimProtocol.html)
* [FitNesse Expressions in Tables guide](https://fitnesse.org/FitNesse.UserGuide.WritingAcceptanceTests.SliM.ExpressionsInTables.html)
* [v20251025 `SlimExpressionEvaluator`](https://github.com/unclebob/fitnesse/blob/20251025/src/fitnesse/slim/SlimExpressionEvaluator.java)
* [v20251025 `VariableStore`](https://github.com/unclebob/fitnesse/blob/20251025/src/fitnesse/slim/VariableStore.java)
* [v20251025 `SlimSymbol`](https://github.com/unclebob/fitnesse/blob/20251025/src/fitnesse/slim/SlimSymbol.java)
* [v20251025 `SlimTable`](https://github.com/unclebob/fitnesse/blob/20251025/src/fitnesse/testsystems/slim/tables/SlimTable.java)
* Upstream page: `FitNesse.SuiteAcceptanceTests.SuiteSlimTests.SlimSymbols.SlimSymbolsCanBeExpressionsToEvaluate`
