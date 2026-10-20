# Typed fixture conversion metadata

The package includes a complete, independent fixture example at
[`examples/lib/Example/Counter.pm`](../examples/lib/Example/Counter.pm) and
its FitNesse page at
[`examples/fitnesse/CounterTest.wiki`](../examples/fitnesse/CounterTest.wiki).
The fixture is outside `t/lib` and can be loaded by an installed server via
`PERL5LIB`. `bin/test-install` copies it to a temporary directory and
verifies its constructor conversion, camelCase method mapping, typed
argument conversion, and result conversion through both SLiM transports and
FitNesse v20251025.

`Test::FitNesse::Slim` does not use Perl reflection to guess Java parameter types. A fixture can declare the types that need conversion and the executor applies its per-session converter registry to method and constructor arguments and method results.

## Method arguments and results

Return metadata from `slim_method_signature` using the dispatched Perl method name:

```perl
sub slim_method_signature {
  my ($self, $method) = @_;
  return {
    parameters => ['java.lang.Integer[]', 'java.util.List<java.lang.Boolean>'],
    return => 'java.util.Collection<java.lang.Integer>',
  } if $method eq 'process_values';
}

sub process_values {
  my ($self, $integers, $flags) = @_;
  # $integers and $flags are array references containing converted values.
  return $integers;
}
```

Double uses the same metadata and registry as every other scalar converter:

```perl
sub slim_method_signature {
  my ($self, $method) = @_;
  return { parameters => ['double', 'java.lang.Double[]'], return => 'java.lang.Double' }
    if $method eq 'echo_double';
}
```

Argument types supported for component conversion are registered scalar types, including `String`, `Boolean`/`java.lang.Boolean`, `boolean`, `Integer`/`java.lang.Integer`, `int`, `Long`/`java.lang.Long`, `long`, `Double`/`java.lang.Double`, `double`, `Character`/`java.lang.Character`, `char`, and `java.util.Date`. Type aliases are accepted for simple names; canonical Java names are preferred.

Supported sequence metadata:

- `T[]` for a one-dimensional typed array.
- `java.util.List<T>` or `List<T>`.
- `java.util.Collection<T>` or `Collection<T>`.

Only registered scalar converters may be used as `T`. Nested generic syntax, multidimensional array parsing, Set, Queue, and reflection-based concrete collection types are not supported.

## Constructor arguments

Use the same type names in `slim_constructor_signature`:

```perl
sub slim_constructor_signature {
  return { parameters => ['int[]', 'java.util.List<java.lang.String>'] };
}
```

The constructor signature uses positional arguments. If metadata is absent, constructor arguments keep their previous untyped behavior.

## Fixed-arity signatures

When a signature contains a `parameters` array, that array declares the exact invocation arity as well as the argument types. The executor checks the count before conversion and before invoking the fixture. A rejected constructor is not run or registered; a rejected method does not run or fall through to the SUT or a library.

```perl
sub slim_enum_types {
  return { Color => [qw(RED GREEN BLUE)] };
}

sub slim_constructor_signature {
  return { parameters => ['Integer', 'java.util.List<String>'] };
}

sub slim_method_signature {
  my ($self, $method) = @_;
  return { parameters => [], return => 'String' }
    if $method eq 'status';       # exactly zero arguments
  return { parameters => ['Integer', 'Color'], return => 'String' }
    if $method eq 'update';       # exactly two arguments
  return { return => 'String' } if $method eq 'describe';
}

sub new { bless { number => $_[1], labels => $_[2] }, $_[0] }
sub status { 'ready' }
sub update { $_[0]{number} = $_[1]; $_[0]{color} = $_[2]; 'updated' }
sub describe { join '/', @_[1 .. $#_] }
```

An explicitly empty `parameters => []` is a fixed zero-argument contract. A signature with no `parameters` key (including a return-only signature) declares no arity contract and retains dynamic Perl invocation behavior. A fixture with no signature metadata is also left untyped; the server does not infer argument counts from Perl prototypes or method bodies. Java overload selection is not emulated: a Perl method has one declared signature per dispatched name.

On a typed mismatch, methods return a structured `NO_METHOD_IN_CLASS` SLiM exception naming the requested method and supplied count; constructors return `NO_CONSTRUCTOR` with the class and supplied count. These categories correspond to Java's arity-based method lookup and constructor rejection, though Java's constructor message is the class name followed by `[count]`. Matching-count conversion errors remain distinct and continue through the existing converter error path. Actor, SUT, and library lookup precedence is unchanged, and a selected target is not retried after an arity mismatch.

## Input and result format

Sequence input uses Java's simple comma-separated syntax. Brackets are optional; values are split on commas and trimmed. There is no quoting or escaping for commas. A blank whole input converts to null. Explicit `[]` converts to an empty array or collection. Blank elements follow their component converter: for example, a blank boxed Integer becomes null, a blank `int` becomes zero, and a blank String remains empty. Invalid values raise the scalar converter error through the usual SLiM exception result.

Typed arrays and typed List/Collection results use Java-style bracketed text such as `[1, 2, 3]`. `callAndAssign` returns that text to FitNesse while retaining the raw Perl array reference in the symbol table. Passing that exact symbol to another typed method preserves the same reference rather than parsing it again. Untyped `java.util.List` results keep their legacy nested SLiM list representation.

At the SLiM wire boundary, the string `null` and the null token share the same spelling. A null reference can be preserved internally through symbols, while an ordinary string containing `null` is not distinguishable after serialization.

The implementation is a fixture metadata feature that composes existing scalar converters. It does not add a protocol type or emulate Java reflection, overload selection, nested generic type inspection, or Java collection classes.

## Enum types

Perl fixtures can declare enum-like domains explicitly. The declaration belongs to the fixture package and is consulted only when that fixture's constructor or method signature names the declared type:

```perl
package Example::Paint;

sub slim_enum_types {
  return {
    Color => [qw(RED GREEN BLUE)],
    'Example::Paint::Mode' => [qw(FAST SAFE)],
  };
}

sub slim_constructor_signature {
  return { parameters => ['Color'] };
}

sub slim_method_signature {
  my ($self, $method) = @_;
  return { parameters => ['Color'], return => 'Color' }
    if $method eq 'repaint';
  return {
    parameters => ['Color[]', 'java.util.List<Color>', 'Collection<Color>'],
    return => 'Color[]',
  } if $method eq 'set_palette';
  return { parameters => ['Example::Paint::Mode'], return => 'Example::Paint::Mode' }
    if $method eq 'set_mode';
}

sub new { bless { color => $_[1], palette => [], mode => undef }, $_[0] }
sub repaint { $_[0]{color} = $_[1] }
sub set_palette { $_[0]{palette} = $_[1]; return $_[1] }
sub set_mode { $_[0]{mode} = $_[1] }
```

`slim_enum_types` returns a hash from an explicit type name to an ordered array of unique, non-empty constant names. Simple and fully qualified names are supported; declarations cannot shadow standard or custom registered converter names. The executor creates converters from this metadata for the current fixture invocation instead of adding enum types to a global or session-wide registry. Two fixtures may therefore declare the same type name with different values.

Exact names are preferred. If there is no exact match, matching follows Java `String.equalsIgnoreCase`: the first matching constant in declaration order is returned. Comparison uses locale-independent Unicode simple case mappings; it does not expand one character into multiple characters. Blank scalar input becomes null through FitNesse's converter base, while nonblank scalar input is not trimmed. The existing typed-sequence parser trims each item before applying its component converter. Unknown values produce a structured conversion error.

Perl represents a declared enum value as its canonical string name. Declared results are checked against the fixture's enum domain and emitted using that canonical name, corresponding to Java's `Enum.name()` even if a Java enum overrides `toString()`. A null result stays null. Typed arrays and List/Collection metadata compose the same enum converter for each element, preserving order and duplicates. Invalid returned names and invalid sequence members are rejected; arbitrary references are never stringified as enums.

This explicit metadata is not Java enum reflection. Perl does not discover Java classes, enum constants, overloads, or methods dynamically, and undeclared scalar strings keep their original untyped behavior.

## Method names

FitNesse v20251025 sends the method spelling unchanged and the Java reference uses exact, case-sensitive method lookup. Perl fixtures commonly use snake_case, so the executor supports one deterministic translation after checking for an exact method name:

```text
setValue             -> set_value
getURL               -> get_url
parseXMLDocument     -> parse_xml_document
getHTTPResponseCode  -> get_http_response_code
isIPv6Enabled        -> is_ipv6_enabled
getUserID            -> get_user_id
reset                -> reset
already_snake_case   -> already_snake_case
```

The resolver splits acronym-to-word boundaries and lower/digit-to-uppercase boundaries. If a Perl fixture defines both `getURL` and `get_url`, an incoming `getURL` calls the exact `getURL`; a request spelled `get_url` calls the snake_case method. There is no case-insensitive or fuzzy scan. Actor lookup still precedes SUT lookup, which precedes newest-first library lookup. The selected Perl spelling is passed to `slim_method_signature`, so typed arguments, exact arity checks, and results remain attached to the invoked method.

For example, this fixture receives a FitNesse call to `parseXMLDocument` and a typed `getHTTPResponseCode` call through the ordinary SLiM `call` instruction:

```perl
sub slim_method_signature {
  my ($self, $method) = @_;
  return { parameters => ['Integer'], return => 'Integer' }
    if $method eq 'get_http_response_code';
  return;
}

sub parse_xml_document { 'parsed' }
sub get_http_response_code { $_[1] }
sub make_a_test_page { 'created' }  # called as makeATestPage
```

A fixture that declares `AUTOLOAD` can handle names that have neither an exact nor translated concrete method. The executor invokes that explicit dynamic hook with the original SLiM spelling and keeps its normal error handling. Without `AUTOLOAD`, a missing method is reported using the original requested name. This is Perl dynamic dispatch support, not Java reflection or overload emulation.

## Double grammar and formatting

The Double converter validates input before calling the platform parser. It accepts Java decimal forms with an optional decimal exponent and optional `f`, `F`, `d`, or `D` suffix; hexadecimal significands require a `p`/`P` binary exponent. The special spellings are case-sensitive `NaN` and `Infinity`, each with an optional sign. Java ASCII trim characters are removed around a number. Other malformed forms, including underscores, lowercase `nan`/`infinity`, and hexadecimal forms without a binary exponent, return `Can't convert <value> to double.`

Boxed whitespace-only values become null; primitive whitespace-only values become positive zero. Signed zero is retained. Decimal and hexadecimal overflow produce infinity; underflow follows round-to-nearest, including signed zero. Formatting emits `NaN`, signed `Infinity`, and signed zero explicitly. Finite values use a shortest precision search verified by parsing each candidate back to the same binary64 bits, followed by Java's notation thresholds: plain notation for decimal exponents -3 through 6, scientific notation otherwise. Scientific output uses uppercase `E`, no leading `+` in the exponent, and at least one digit after the decimal point.

Reference evidence comes from the converter classes in `/opt/fitnesse/fitnesse.jar` v20251025 using the installed OpenJDK 25 runtime. The Perl implementation uses core `POSIX::strtod` under the C numeric locale and requires a binary64 Perl NV. It matched `Double.toString` for the focused edge vectors and 1,000 deterministic random finite binary64 values. This is strong platform-specific evidence, not an exhaustive proof for every value or every POSIX libc implementation.
