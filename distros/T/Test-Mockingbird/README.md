# NAME

Test::Mockingbird - Advanced mocking library for Perl with support for
dependency injection, spies, call ordering, constructor interception, and
async Future mocking

# VERSION

Version 0.12

# SYNOPSIS

    use Test::Mockingbird;

    # Mocking (shorthand form)
    mock 'My::Module::method' => sub { 'mocked' };

    # Mocking (longhand form)
    mock('My::Module', 'method', sub { 'mocked' });

    # Spying
    my $spy = spy 'My::Module::method';
    My::Module::method('arg1');
    my @calls = $spy->();   # ( ['My::Module::method', 'arg1'], ... )

    # Dependency injection
    inject 'My::Module::Dependency' => $mock_object;

    # Batch dependency injection
    inject_all('My::Module', {
        DB     => $mock_db,
        Logger => $mock_logger,
    });

    # Constructor interception
    intercept_new 'My::Service' => $stub_obj;
    intercept_new 'My::Service' => sub { My::Double->new(@_[1..$#_]) };

    # Unmock one layer
    unmock 'My::Module::method';

    # Restore everything
    restore_all();

    # Call ordering
    spy 'A::fetch';
    spy 'B::process';
    A::fetch();
    B::process();
    assert_call_order('A::fetch', 'B::process');
    clear_call_log();

# DESCRIPTION

Test::Mockingbird provides mocking, spying, dependency injection,
call-order verification, and constructor interception for Perl test suites.

# DIAGNOSTICS

## diagnose\_mocks

Returns a structured hashref of all active mock layers.

## diagnose\_mocks\_pretty

Returns a human-readable multi-line string of all active mock layers.

## Diagnostic Metadata

Each installed layer records:

    type          -- category (mock, spy, inject, mock_return, ...)
    installed_at  -- file and line number of the outermost user call site

# LIMITATIONS

- `->can()` may return truthy after unmocking a never-existed method

    Perl's typeglob (GV) system auto-vivifies a GV entry the first time
    `\&{$full_method}` is called internally (in `mock()`, `spy()`, or
    `inject()`). After unmocking, this GV entry remains in the stash with an
    "undefined sub" placeholder in the CODE slot. `Package->can('method')`
    tests the GV's existence in the stash, not whether the CODE slot is defined,
    so it may still return a truthy value.

    To test whether a sub is callable, use `defined(&Package::method)` rather
    than `Package->can('method')`. `defined(&...)` correctly returns false
    for the placeholder stub. Calling the stub dies with `"Undefined subroutine"`.

    Deleting the GV from the stash (via `delete $stash{method}`) would make
    `->can()` return false but would break subsequent mock/inject stacking:
    compiled direct calls (`Package::method()`) cache the GV at compile time,
    so a new GV installed after a delete is invisible to those compiled calls.

- Prototype mismatch warning from `spy()`

    `spy()` installs its wrapper directly without going through `mock()`,
    so `Scalar::Util::set_prototype` is not applied. Wrapping a prototyped
    function with `spy()` still emits a `Prototype mismatch` warning. Use
    `mock()` with a delegating wrapper if warning-free wrapping is required.

- No nested deep\_mock scopes

    [Test::Mockingbird::DeepMock](https://metacpan.org/pod/Test%3A%3AMockingbird%3A%3ADeepMock) calls `restore_all()` at scope exit, which
    removes every active mock. Nested `deep_mock` blocks cause the inner exit
    to also tear down the outer mocks. Do not nest `deep_mock` calls.

- Thread safety

    The internal state (`%mocked`, `%mock_meta`, `@call_log`) is per-process
    lexical state. Concurrent threads that install and restore mocks will race.
    Do not use this module in threaded test harnesses without external locking.

- Spy return value is a flat list

    `spy()` and `async_spy()` return a coderef that yields a flat list of
    call records. A future version may return an arrayref to reduce stack
    pressure; the API is not yet changed to avoid breaking callers.

- Private-function encapsulation

    Functions prefixed with `_` are private by convention but are not enforced
    at runtime (`Sub::Private` is not activated). White-box tests in `t/unit.t`
    call private functions directly. If `Sub::Private` enforcement is added, a
    testing-interface export mechanism will be required.

# METHODS

## mock

Replace a method with a coderef.

    mock('My::Module', 'method', sub { 'mocked' });
    mock 'My::Module::method' => sub { 'mocked' };

Mocks stack in LIFO order. Each `mock()` call saves the current CODE slot
(or the auto-vivified undef stub if the method does not exist) and installs
the replacement. `unmock()` pops one layer; `restore_all()` drains all.

If the original carries a Perl prototype, the same prototype is stamped onto
the replacement coderef before installation, suppressing `Prototype mismatch`
warnings.

### API SPECIFICATION

#### Input

    target      -- Str, 'Pkg::method' or ('Pkg', 'method')
    replacement -- CodeRef

#### Output

    returns: undef

### MESSAGES

    "Package, method and replacement are required" -- target or coderef missing

## unmock

Restore the previous implementation of a mocked method (one layer).

    unmock('My::Module', 'method');
    unmock 'My::Module::method';

If the method did not exist before it was mocked, the original undef-stub
is restored so that calling the method dies with `"Undefined subroutine"`.
Note: `->can()` may still return truthy; use `defined(&...)` to test
whether a method is callable. See ["LIMITATIONS"](#limitations).

### API SPECIFICATION

#### Input

    target -- Str, 'Pkg::method' or ('Pkg', 'method')

#### Output

    returns: undef

### MESSAGES

    "Package and method are required for unmocking" -- target missing

## before

Run a hook before a method, then call the original and return its value.

    before 'My::Module::method' => sub { my @args = @_; ... };
    before('My::Module', 'method', sub { ... });

The hook receives the same `@_` that the original would have received. Its
return value is discarded. The original is always called and its return value
is passed to the caller unchanged. Context (list / scalar / void) is
preserved.

Uses the same LIFO mock stack as `mock()`: `unmock()` peels one layer,
`restore_all()` drains all. `diagnose_mocks()` records the layer type as
`'before'`.

### API SPECIFICATION

#### Input

    target -- Str, 'Pkg::method' or ('Pkg', 'method')
    hook   -- CodeRef; receives (@original_args), return value discarded

#### Output

    returns: undef

### MESSAGES

    "Package, method and hook are required for before()" -- target or hook missing or non-CODE

## after

Run a hook after a method and return the original's value.

    after 'My::Module::method' => sub { my @args = @_; ... };
    after('My::Module', 'method', sub { ... });

The original is called first. Its return value is captured, then the hook is
called with the same `@_` that the original received. The hook's return
value is discarded and the original's return value is passed to the caller
unchanged. Context (list / scalar / void) is preserved.

If the original throws, the exception propagates immediately and the hook is
**not** called. Use `around()` if you need to run code unconditionally after
the original.

Uses the same LIFO mock stack as `mock()`: `unmock()` peels one layer,
`restore_all()` drains all. `diagnose_mocks()` records the layer type as
`'after'`.

### API SPECIFICATION

#### Input

    target -- Str, 'Pkg::method' or ('Pkg', 'method')
    hook   -- CodeRef; receives (@original_args), return value discarded

#### Output

    returns: undef

### MESSAGES

    "Package, method and hook are required for after()" -- target or hook missing or non-CODE

## around

Replace a method with a hook that receives the original coderef as its first
argument.

    around 'My::Module::method' => sub {
        my ($orig, @args) = @_;
        my $result = $orig->(@args);   # call original
        return $result * 2;            # modify return value
    };

    around('My::Module', 'method', sub {
        my ($orig, @args) = @_;
        return $orig->(@args);
    });

The hook receives `($orig_coderef, @original_args)`. It may call `$orig`
zero or more times with any arguments. Its return value becomes the return
value of the method. The hook is responsible for context handling when that
matters.

`around()` is the preferred alternative to `mock()` when you need to call
through to the original: it captures the original and passes it as the first
argument, avoiding the boilerplate of a separate `\&{...}` capture.

Uses the same LIFO mock stack as `mock()`: `unmock()` peels one layer,
`restore_all()` drains all. `diagnose_mocks()` records the layer type as
`'around'`.

### API SPECIFICATION

#### Input

    target -- Str, 'Pkg::method' or ('Pkg', 'method')
    hook   -- CodeRef; receives ($orig_coderef, @original_args)

#### Output

    returns: undef

### MESSAGES

    "Package, method and hook are required for around()" -- target or hook missing or non-CODE

## mock\_scoped

Create a scoped mock that restores automatically when the guard goes out of scope.

### Single-method forms

    my $g = mock_scoped 'My::Module::method' => sub { 'mocked' };
    my $g = mock_scoped('My::Module', 'method', sub { ... });

### Multi-method forms

    my $g = mock_scoped('My::Module',
        fetch  => sub { 'mocked_fetch'  },
        save   => sub { 'mocked_save'   },
    );

    my $g = mock_scoped(
        'My::Module::fetch'  => sub { 'mocked_fetch'  },
        'Other::Module::save' => sub { 'mocked_save'  },
    );

All mocked methods are restored when `$g` goes out of scope.

### API SPECIFICATION

#### Input

    args -- four recognised forms (see above)

#### Output

    returns: Test::Mockingbird::Guard

### MESSAGES

    "mock_scoped: unrecognised argument form" -- none of the four forms matched
    "mock_scoped: expected coderef for '$target'" -- non-CODE value provided

## spy

Wrap a method so that every call is recorded. The original method is still
called and its return value is passed back to the caller.

    my $spy = spy 'My::Module::method';
    My::Module::method('arg');
    my @calls = $spy->();   # ( ['My::Module::method', 'arg'], ... )
    restore_all();

Returns a coderef that, when invoked, returns the list of captured call
records. Each record is an arrayref `[ $full_method, @args ]`.

### Limitation

`spy()` does not call `mock()` internally and therefore does not apply
prototype preservation. Wrapping a prototyped function emits a
`Prototype mismatch` warning.

### API SPECIFICATION

#### Input

    target -- Str, 'Pkg::method' or ('Pkg', 'method')

#### Output

    returns: CodeRef   # yields list of call records on invocation

### MESSAGES

    "Package and method are required for spying" -- target missing or incomplete

## inject

Inject a mock dependency into a package.

    inject('My::Module', 'Dependency', $mock_object);
    inject 'My::Module::Dependency' => $mock_object;

Injecting `undef` is valid; use argument count (not definedness of the
third argument) to distinguish shorthand from longhand.

### API SPECIFICATION

#### Input

    package    -- Str
    dependency -- Str
    value      -- Any (including undef)

#### Output

    returns: undef

### MESSAGES

    "Package and dependency are required for injection" -- missing name

## inject\_all

Inject multiple dependencies into a package in one call.

    inject_all('My::Service', {
        DB     => $mock_db,
        Logger => $mock_logger,
    });

An empty hashref is a no-op. Each pair is equivalent to a separate
`inject()` call and participates in the same mock stack.

### API SPECIFICATION

#### Input

    package      -- Str
    dependencies -- HashRef

#### Output

    returns: undef

### MESSAGES

    "inject_all requires a package name"            -- undef or empty package
    "inject_all requires a hashref of dependencies" -- second arg not a HashRef

## intercept\_new

Intercept the `new` constructor of a class.

    intercept_new 'My::Service' => $stub_obj;
    intercept_new 'My::Service' => sub { My::Double->new(@_[1..$#_]) };

When given a plain value (including undef), every call to
`My::Service->new` returns that value. When given a coderef, every
call invokes the coderef with the original arguments (including the class
name as the first argument) and returns its result.

This is a thin wrapper around `mock()`; `restore_all()`, `unmock()`,
and `diagnose_mocks()` all work identically.

### API SPECIFICATION

#### Input

    class   -- Str (non-empty)
    factory -- Any; CodeRef invoked per call, or scalar returned verbatim

#### Output

    returns: undef

### MESSAGES

    "intercept_new requires a class name"                    -- undef/empty class
    "intercept_new requires a replacement object or coderef" -- factory missing

## restore\_all

Restore all mocked methods and injected dependencies.

    restore_all();            # restore everything
    restore_all 'My::Module'; # restore only My::Module's mocks

When called with a package name, only mocks whose fully-qualified names
begin with that package are restored. The call-order log is pruned to
remove entries for the restored package.

### API SPECIFICATION

#### Input

    package -- Str, optional

#### Output

    returns: undef

## restore

Restore all mock layers for a single method target.

    restore 'My::Module::method';

If the method was never mocked this is a no-op.

### API SPECIFICATION

#### Input

    target -- Str

#### Output

    returns: undef

### MESSAGES

    "restore requires a target" -- undef target

## mock\_return

Mock a method to always return a fixed value.

    mock_return 'My::Module::method' => 42;

### API SPECIFICATION

#### Input

    target -- Str
    value  -- Any

#### Output

    returns: undef

### MESSAGES

    "mock_return requires a target and a value" -- target undefined

## mock\_exception

Mock a method to always throw an exception.

    mock_exception 'My::Module::method' => 'something went wrong';

### API SPECIFICATION

#### Input

    target  -- Str
    message -- Str

#### Output

    returns: undef

### MESSAGES

    "mock_exception requires a target and an exception message" -- either missing

## mock\_sequence

Mock a method to return a sequence of values over successive calls.
The last value repeats when the sequence is exhausted.

    mock_sequence 'My::Module::method' => (1, 2, 3);

### API SPECIFICATION

#### Input

    target -- Str
    values -- Array (one or more)

#### Output

    returns: undef

### MESSAGES

    "mock_sequence requires a target and at least one value" -- empty value list

## mock\_once

Install a mock that fires exactly once. After the first call the previous
implementation is automatically restored.

    mock_once 'My::Module::method' => sub { 'temporary' };

### API SPECIFICATION

#### Input

    target -- Str
    code   -- CodeRef

#### Output

    returns: undef

### MESSAGES

    "mock_once requires a target and a coderef" -- missing or non-CODE factory

### PSEUDOCODE

    parse target → (package, method)
    wrapper = sub {
        result = code(@_)
        unmock(package, method)   -- pop this very layer
        return result
    }
    install wrapper via mock() with TYPE='mock_once'

## assert\_call\_order

Assert that the named methods were called in left-to-right order.

    assert_call_order('A::fetch', 'B::process', 'C::save');

Produces one TAP ok/not-ok line and returns a boolean. Intervening calls
to other methods are ignored.

### API SPECIFICATION

#### Input

    methods -- Array of Str (two or more fully-qualified names)

#### Output

    returns: Bool

### MESSAGES

    "assert_call_order requires at least two method names" -- fewer than two given

## clear\_call\_log

Clear the call-order log without restoring mocks or spies.

    clear_call_log();

`restore_all()` also clears the log automatically.

### API SPECIFICATION

#### Input

    none

#### Output

    returns: undef

## diagnose\_mocks

Return a structured hashref of all currently active mock layers.

    my $diag = diagnose_mocks();
    # $diag->{'My::Pkg::method'} = {
    #   depth            => 1,
    #   layers           => [ { type => 'mock_return', installed_at => '...' } ],
    # }

### API SPECIFICATION

#### Input

    none

#### Output

    returns: HashRef

## diagnose\_mocks\_pretty

Return a human-readable multi-line string of all active mock layers.

### API SPECIFICATION

#### Input

    none

#### Output

    returns: Str

# SUPPORT

Please report bugs at [https://github.com/nigelhorne/Test-Mockingbird/issues](https://github.com/nigelhorne/Test-Mockingbird/issues).

# AUTHOR

Nigel Horne, `<njh at nigelhorne.com>`

# SEE ALSO

- [Test Dashboard](https://nigelhorne.github.io/Test-Mockingbird/coverage/)
- [Test::Mockingbird::Async](https://metacpan.org/pod/Test%3A%3AMockingbird%3A%3AAsync)
- [Test::Mockingbird::DeepMock](https://metacpan.org/pod/Test%3A%3AMockingbird%3A%3ADeepMock)
- [Test::Mockingbird::TimeTravel](https://metacpan.org/pod/Test%3A%3AMockingbird%3A%3ATimeTravel)

# REPOSITORY

[https://github.com/nigelhorne/Test-Mockingbird](https://github.com/nigelhorne/Test-Mockingbird)

# FORMAL SPECIFICATION

## mock

    mock ≙
      ∀ target : Str; replacement : CodeRef •
        pre  target ≠ '' ∧ defined(replacement)
        post mocked'[target] = ⟨saved(target)⟩ ⌢ mocked[target]
             ∧ sym_table'[target].CODE = replacement
             ∧ prototype(replacement) = prototype(saved(target))

## unmock

    unmock ≙
      ∀ target : Str •
        let prev = head(mocked[target]) •
          post mocked'[target] = tail(mocked[target])
               ∧ sym_table'[target].CODE = prev
               ∧ mock_meta'[target] = tail(mock_meta[target])

## before

    before ≙
      ∀ target : Str; hook : CodeRef •
        pre  target ≠ '' ∧ ref(hook) = 'CODE'
        let orig = sym_table[target].CODE •
          post sym_table'[target].CODE = wrapper
               ∧ wrapper(@args) ≙ hook(@args); orig(@args)

## after

    after ≙
      ∀ target : Str; hook : CodeRef •
        pre  target ≠ '' ∧ ref(hook) = 'CODE'
        let orig = sym_table[target].CODE •
          post sym_table'[target].CODE = wrapper
               ∧ wrapper(@args) ≙ let ret = orig(@args) • hook(@args); ret

## around

    around ≙
      ∀ target : Str; hook : CodeRef •
        pre  target ≠ '' ∧ ref(hook) = 'CODE'
        let orig = sym_table[target].CODE •
          post sym_table'[target].CODE = wrapper
               ∧ wrapper(@args) ≙ hook(orig, @args)

## mock\_scoped

    mock_scoped ≙
      install all mocks via mock()
      ∧ return Guard(full_methods)
      ∧ Guard.DESTROY ⇒ ∀ m ∈ full_methods • unmock(m)

## spy

    spy ≙
      ∀ target : Str •
        pre  defined(target)
        post sym_table'[target].CODE = wrapper(orig)
             ∧ wrapper: @args → (calls' = calls ⌢ ⟨[target, @args]⟩ ∧ orig(@args))

## inject

    inject ≙
      ∀ pkg : Str; dep : Str; val : Any •
        pre  pkg ≠ '' ∧ dep ≠ ''
        post sym_table'["${pkg}::${dep}"].CODE = sub { val }

## inject\_all

    inject_all ≙
      ∀ pkg : Str; deps : HashRef •
        post ∀ (k,v) ∈ deps • inject(pkg, k, v)

## intercept\_new

    intercept_new ≙
      ∀ class : Str; factory : Any •
        pre  class ≠ '' ∧ @args ≥ 2
        let  rep = (factory : CodeRef) ? factory : sub { factory } •
          post mock("${class}::new", rep)

## restore\_all

    restore_all ≙
      global: mocked' = {} ∧ mock_meta' = {} ∧ call_log' = []
      scoped: ∀ target ∈ dom(mocked) • target =~ /^pkg::/ ⇒ unmock_all(target)
              ∧ call_log' = [ e ∈ call_log | e !~ /^pkg::/ ]

## restore

    restore ≙
      ∀ target : Str •
        pre  defined(target)
        post mocked[target] = []

## mock\_return

    mock_return ≙
      ∀ target : Str; value : Any •
        post sym_table'[target].CODE = sub { value }

## mock\_exception

    mock_exception ≙
      ∀ target : Str; msg : Str •
        post sym_table'[target].CODE = sub { croak msg }

## mock\_sequence

    mock_sequence ≙
      ∀ target : Str; values : Seq(Any) •
        pre  |values| ≥ 1
        post let queue = values •
          sym_table'[target].CODE = sub { head(queue) if |queue|=1 else shift(queue) }

## mock\_once

    mock_once ≙
      ∀ target : Str; code : CodeRef •
        post sym_table'[target] = sub {
          result = code(@args)
          unmock(target)
          return result
        }

## assert\_call\_order

    assert_call_order ≙
      ∀ expected : Seq(Str) •
        pre  |expected| ≥ 2
        post result = (∀ i • ∃ p_i : ℕ | p_0 < p_1 < … ∧ call_log[p_i] = expected[i])

## clear\_call\_log

    clear_call_log ≙ post call_log' = []

## diagnose\_mocks

    diagnose_mocks ≙
      returns { target ↦ { depth, layers } | target ∈ dom(mocked) }

## diagnose\_mocks\_pretty

    diagnose_mocks_pretty ≙ stringify(diagnose_mocks())

## before

    before ≙
      ∀ target : Str; hook : CodeRef •
        pre  target ≠ '' ∧ ref(hook) = 'CODE'
        let orig = sym_table[target].CODE •
          post sym_table'[target].CODE = wrapper
               ∧ wrapper(@args) ≙ hook(@args); orig(@args)

## after

    after ≙
      ∀ target : Str; hook : CodeRef •
        pre  target ≠ '' ∧ ref(hook) = 'CODE'
        let orig = sym_table[target].CODE •
          post sym_table'[target].CODE = wrapper
               ∧ wrapper(@args) ≙
                   let ret = orig(@args) •
                   hook(@args);
                   ret

## around

    around ≙
      ∀ target : Str; hook : CodeRef •
        pre  target ≠ '' ∧ ref(hook) = 'CODE'
        let orig = sym_table[target].CODE •
          post sym_table'[target].CODE = wrapper
               ∧ wrapper(@args) ≙ hook(orig, @args)

# LICENCE AND COPYRIGHT

Copyright 2025-2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.
