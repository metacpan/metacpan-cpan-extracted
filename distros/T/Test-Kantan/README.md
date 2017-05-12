[![Build Status](https://travis-ci.org/tokuhirom/Test-Kantan.png?branch=master)](https://travis-ci.org/tokuhirom/Test-Kantan)
# NAME

Test::Kantan - simple, flexible, fun "Testing framework"

# SYNOPSIS

    use Test::Kantan;

    describe 'String', sub {
      describe 'index', sub {
        it 'should return -1 when the value is not matched', sub {
          expect(index("abc", 'x'))->to_be(-1);
          expect(index("abc", 'a'))->to_be(0);
        };
      };
    };

    done_testing;

# DESCRIPTION

Test::Kantan is a behavior-driven development framework for testing Perl 5 code.
It has a clean, obvious syntax so that you can easily write tests.

# CURRENT STATUS

Unstable. I will change the API without notice.

# Interfaces

There is 3 types for describing test cases.

## BDD style

RSpec/Jasmine like BDD style function names are available.

    describe 'String', sub {
      before_each { ... };
      describe 'index', sub {
        it 'should return -1 when the value is not matched', sub {
          expect(index("abc", 'x'))->to_be(-1);
          expect(index("abc", 'a'))->to_be(0);
        };
      };
    };

    done_testing;

## Given-When-Then style

There is the Given-When-Then style functions.
It's really useful for describing real complex problems.

    Scenario 'String', sub {
      setup { ... };

      Feature 'Get the index from the code', sub {
        Given 'the string';
        my $str = 'abc';

        When 'get the index for "a"';
        my $i = index($str, 'a');

        Then 'the return value is 0';
        expect($i)->to_be(0);
      };
    };

    done_testing;

## Plain old Test::More style

    subtest 'String', sub {
      setup { ... };

      subtest 'index', sub {
        expect(index("abc", 'x'))->to_be(-1);
        expect(index("abc", 'a'))->to_be(0);
      };
    };

    done_testing;

# Assertions

Here is 2 type assertions.

## `ok()`

    ok { 1 };

There is the `ok` function. It takes one code block. The code returns true value if the test case was passed, false otherwise.

`ok()` returns the value what returned by the code.

## `expect()`

    expect($x)->to_be_true;

Here is the `expect` function like RSpec/Jasmine. For more details, please look [Test::Kantan::Expect](https://metacpan.org/pod/Test::Kantan::Expect).

# Utility functions

## ` diag($message) `

You can show the diagnostic message with ` diag() ` function.
Diagnostic message would not print if whole test cases in the subtest were passed.

It means, you can call diag() without worries about the messages is a obstacle.

## `ignore()`

The same as [Test::Deep::NoTest](https://metacpan.org/pod/Test::Deep::NoTest)'s one. See also ["ignore()" in Test::Deep](https://metacpan.org/pod/Test::Deep#ignore)

## `spy_on()`

The same as ["spy\_on()" in Module::Spy](https://metacpan.org/pod/Module::Spy#my-spy-spy_on-class-object-method)

## `skip_all()`

Skips all of the tests that are in the hereafter.

# Hooks

## `setup()`

    setup { do_something() };

`setup` blocks are run before each example `setup` blocks are run once before all of the examples in a group.

## `teardown()`

    teardown { do_something() };

`teardown` blocks are run after each example `teardown` blocks are run once after all of the examples in a group.

## `before_each()`

Alias of `setup()`.

## `after_each`

Alias of `teardown()`.

# ENVIRONMENT VARIABLES

- KANTAN\_REPORTER

    You can specify the reporter class by KANTAN\_REPORTER environment variable.

        KANTAN_REPORTER=TAP perl -Ilib t/01_simple.t

- KANTAN\_CUTOFF

    Kantan cut the diagnostic message by 80 bytes by default.
    If you want to change this value, you can set by KANTAN\_CUTOFF.

        KANTAN_CUTOFF=10000 perl -Ilib t/01_simple.t

# Tips

## How do I suppress output from Log::Minimal?

Log::Minimal outputs logs to STDERR by default.

    $Log::Minimal::PRINT = sub {
        my ( $time, $type, $message, $trace,$raw_message) = @_;
        local $Test::Kantan::Level = $Test::Kantan::Level + 3;
        Test::Kantan::diag("$time [$type] $message at $trace", 1024);
    };

# How do I use the testing library based on Test::Builder?

Test::Kantan replace some methods in Test::Builder.
You can use the library based on Test::Builder with Test::Kantan :)

# LICENSE

Copyright (C) Tokuhiro Matsuno.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Tokuhiro Matsuno <tokuhirom@gmail.com>

moznion

Kuniwak
