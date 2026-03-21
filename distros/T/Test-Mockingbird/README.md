# NAME

Test::Mockingbird - Advanced mocking library for Perl with support for dependency injection and spies

# VERSION

Version 0.06

# SYNOPSIS

    use Test::Mockingbird;

    # Mocking
    Test::Mockingbird::mock('My::Module', 'method', sub { return 'mocked!' });

    # Spying
    my $spy = Test::Mockingbird::spy('My::Module', 'method');
    My::Module::method('arg1', 'arg2');
    my @calls = $spy->(); # Get captured calls

    # Dependency Injection
    Test::Mockingbird::inject('My::Module', 'Dependency', $mock_object);

    # Unmocking
    Test::Mockingbird::unmock('My::Module', 'method');

    # Restore everything
    Test::Mockingbird::restore_all();

# DESCRIPTION

Test::Mockingbird provides powerful mocking, spying, and dependency injection capabilities to streamline testing in Perl.

# DIAGNOSTICS

Test::Mockingbird provides optional, non-intrusive diagnostic routines
that allow inspection of the current mocking state during test execution.
These routines are purely observational. They do not modify any mocking
behaviour, symbol table entries, or internal state.

Diagnostics are useful when debugging complex test suites, verifying
mock layering behaviour, or understanding interactions between multiple
mocking primitives such as mock, spy, inject, and the sugar functions.

## diagnose\_mocks

Return a structured hashref describing all currently active mock layers.
Each entry includes the fully qualified method name, the number of active
layers, whether the original method existed, and metadata for each layer
(type and installation location). See the diagnose\_mocks method for full
API details.

## diagnose\_mocks\_pretty

Return a human-readable, multi-line string describing all active mock
layers. This routine is intended for debugging and inspection during test
development. The output format is stable for human consumption but is not
guaranteed for machine parsing. See the diagnose\_mocks\_pretty method for
full API details.

## Diagnostic Metadata

Diagnostic information is recorded automatically whenever a mock layer is
successfully installed. Each layer records:

    * type          The category of mock layer (for example: mock, spy,
                    inject, mock_return, mock_exception, mock_sequence,
                    mock_once, mock_scoped)

    * installed_at  The file and line number where the layer was created

This metadata is maintained in parallel with the internal mock stack and
is automatically cleared when a method is fully restored via unmock or
restore\_all.

Diagnostics never alter the behaviour of the mocking engine and may be
safely invoked at any point during a test run.

# DEBUGGING EXAMPLES

This section provides practical examples of using the diagnostic routines
to understand and debug complex mocking behaviour.
All examples are safe to run inside test files and do not modify mocking semantics.

## Example 1: Inspecting a simple mock

    {
        package Demo::One;
        sub value { 1 }
    }

    mock_return 'Demo::One::value' => 42;

    my $diag = diagnose_mocks();
    print diagnose_mocks_pretty();

The output will resemble:

    Demo::One::value:
      depth: 1
      original_existed: 1
      - type: mock_return   installed_at: t/example.t line 12

This confirms that the method has exactly one active mock layer and shows
where it was installed.

## Example 2: Stacked mocks

    {
        package Demo::Two;
        sub compute { 10 }
    }

    mock_return    'Demo::Two::compute' => 20;
    mock_exception 'Demo::Two::compute' => 'fail';

    print diagnose_mocks_pretty();

Possible output:

    Demo::Two::compute:
      depth: 2
      original_existed: 1
      - type: mock_return   installed_at: t/example.t line 8
      - type: mock_exception installed_at: t/example.t line 9

This shows the order in which layers were applied. The most recent layer
appears last.

## Example 3: Spies and injected dependencies

    {
        package Demo::Three;
        sub action { 1 }
        sub dep    { 2 }
    }

    spy 'Demo::Three::action';
    inject 'Demo::Three::dep' => sub { 99 };

    print diagnose_mocks_pretty();

Example output:

    Demo::Three::action:
      depth: 1
      original_existed: 1
      - type: spy           installed_at: t/example.t line 7

    Demo::Three::dep:
      depth: 1
      original_existed: 1
      - type: inject        installed_at: t/example.t line 8

This confirms that both the spy and the injected dependency are active.

## Example 4: After restore\_all

    mock_return 'Demo::Four::x' => 5;
    restore_all();

    print diagnose_mocks_pretty();

Output:

    (no output)

After restore\_all, all diagnostic metadata is cleared along with the
mock layers.

## Example 5: Using diagnostics inside a failing test

When a test fails unexpectedly, adding the following line can help
identify the active mocks:

    diag diagnose_mocks_pretty();

This prints the current mocking state into the test output without
affecting the test run.

# METHODS

## mock($package, $method, $replacement)

Mocks a method in the specified package.
Supports two forms:

    mock('My::Module', 'method', sub { ... });

or the shorthand:

    mock 'My::Module::method' => sub { ... };

## unmock($package, $method)

Restores the original method for a mocked method.
Supports two forms:

    unmock('My::Module', 'method');

or the shorthand:

    unmock 'My::Module::method';

## mock\_scoped

Creates a scoped mock that is automatically restored when it goes out of scope.

This behaves like `mock`, but instead of requiring an explicit call to
`unmock` or `restore_all`, the mock is reverted automatically when the
returned guard object is destroyed.

This is useful when you want a mock to apply only within a lexical block:

    {
        my $g = mock_scoped 'My::Module::method' => sub { 'mocked' };
        My::Module::method();   # returns 'mocked'
    }

    My::Module::method();       # original behaviour restored

Supports both the longhand and shorthand forms:

    my $g = mock_scoped('My::Module', 'method', sub { ... });

    my $g = mock_scoped 'My::Module::method' => sub { ... };

Returns a guard object whose destruction triggers automatic unmocking.

## spy($package, $method)

Wraps a method so that all calls and arguments are recorded.
Supports two forms:

    spy('My::Module', 'method');

or the shorthand:

    spy 'My::Module::method';

Returns a coderef which, when invoked, returns the list of captured calls.
The original method is preserved and still executed.

## inject($package, $dependency, $mock\_object)

Injects a mock dependency. Supports two forms:

    inject('My::Module', 'Dependency', $mock_object);

or the shorthand:

    inject 'My::Module::Dependency' => $mock_object;

The injected dependency can be restored with `restore_all` or `unmock`.

## restore\_all()

Restores mocked methods and injected dependencies.

Called with no arguments, it restores everything:

    restore_all();

You may also restore only a specific package:

    restore_all 'My::Module';

This restores all mocked methods whose fully qualified names begin with
`My::Module::`.

## mock\_return

Mock a method so that it always returns a fixed value.

Takes a single target (either `'Pkg::method'` or `('Pkg','method')`) and
a value to return. Returns nothing. Side effects: installs a mock layer
using ["mock"](#mock).

### API specification

#### Input

Params::Validate::Strict schema:

\- `target`: required, scalar, string; method target in shorthand or longhand form
\- `value`: required, any type; value to be returned by the mock

#### Output

Returns::Set schema:

\- `return`: undef

## mock\_exception

Mock a method so that it always throws an exception.

Takes a single target (either `'Pkg::method'` or `('Pkg','method')`) and
an exception message. Returns nothing. Side effects: installs a mock layer
using ["mock"](#mock).

### API specification

#### Input

Params::Validate::Strict schema:

\- `target`: required, scalar, string; method target in shorthand or longhand form
\- `message`: required, scalar, string; exception text to `croak` with

#### Output

Returns::Set schema:

\- `return`: undef

## mock\_sequence

Mock a method so that it returns a sequence of values over successive calls.

Takes a single target (either `'Pkg::method'` or `('Pkg','method')`) and
one or more values. Returns nothing. Side effects: installs a mock layer
using ["mock"](#mock). When the sequence is exhausted, the last value is repeated.

### API specification

#### Input

Params::Validate::Strict schema:

\- `target`: required, scalar, string; method target in shorthand or longhand form
\- `values`: required, array; one or more values to be returned in order

#### Output

Returns::Set schema:

\- `return`: undef

## mock\_once

Install a mock that is executed exactly once. After the first call, the
previous implementation is automatically restored. This is useful for
testing retry logic, fallback behaviour, and state transitions.

### API specification

#### Input (Params::Validate::Strict schema)

\- `target`: required, scalar, string; method target in shorthand or longhand form
\- `code`: required, coderef; mock implementation to run once

#### Output (Returns::Set schema)

\- `return`: undef

## restore

Restore all mock layers for a single method target. This is similar to
`restore_all`, but applies only to one method. If the method was never
mocked, this routine has no effect.

### API specification

#### Input (Params::Validate::Strict schema)

\- `target`: required, scalar, string; method target in shorthand or longhand form

#### Output (Returns::Set schema)

\- `return`: undef

## diagnose\_mocks

Return a structured hashref describing all currently active mock layers.
This routine is purely observational and does not modify any state.

### API specification

#### Input

Params::Validate::Strict schema:

\- none

#### Output

Returns::Set schema:

\- `return`: hashref; keys are fully qualified method names, values are
  hashrefs containing:
  - `depth`: integer; number of active mock layers
  - `layers`: arrayref of hashrefs; each layer has:
      - `type`: string
      - `installed_at`: string
  - `original_existed`: boolean

## diagnose\_mocks\_pretty

Return a human-readable string describing all currently active mock layers.
This routine is purely observational and does not modify any state.

### API specification

#### Input

Params::Validate::Strict schema:

\- none

#### Output

Returns::Set schema:

\- `return`: scalar string; formatted multi-line description of all active
  mock layers, including:
  - fully qualified method name
  - depth (number of active layers)
  - whether the original method existed
  - each layer's type and installation location

### Behaviour

#### Entry

\- No arguments are accepted.

#### Exit

\- Returns a formatted string describing the current mocking state.

#### Side effects

\- None. This routine does not modify `%mocked`, `%mock_meta`, or any
  symbol table entries.

#### Notes

\- This routine is intended for debugging and diagnostics. It is safe to
  call at any point during a test run.
\- The output format is stable and suitable for human inspection, but not
  guaranteed to remain fixed for machine parsing.

# SUPPORT

This module is provided as-is without any warranty.

Please report any bugs or feature requests to `bug-test-mockingbird at rt.cpan.org`,
or through the web interface at
[http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Mockingbird](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Mockingbird).
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

You can find documentation for this module with the perldoc command.

    perldoc Test::Mockingbird

# AUTHOR

Nigel Horne, `<njh at nigelhorne.com>`

# BUGS

# SEE ALSO

- [Test::Mockingbird::DeepMock](https://metacpan.org/pod/Test%3A%3AMockingbird%3A%3ADeepMock)

# REPOSITORY

[https://github.com/nigelhorne/Test-Mockingbird](https://github.com/nigelhorne/Test-Mockingbird)

# SUPPORT

This module is provided as-is without any warranty.

# LICENCE AND COPYRIGHT

Copyright 2025-2026 Nigel Horne.

Usage is subject to licence terms.

The licence terms of this software are as follows:

- Personal single user, single computer use: GPL2
- All other users (including Commercial, Charity, Educational, Government)
  must apply in writing for a licence for use from Nigel Horne at the
  above e-mail.
