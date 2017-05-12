# NAME

Test::Retry - Retry test functions on failure

# SYNOPSIS

    use Test::Retry;

    # Retries for 5 times with 0.5 secs delay each
    retry_test {
        is func_with_some_random_lag(), $expected;
    };

    # or override existing test functions

    BEGIN { Test::Retry->override('is') }

    is { func_with_some_random_lag(), $expected };

# DESCRIPTION

Test::Retry provides feature to retry code until a test succeeds (with retry limits).

Useful for tests which involves I/O and requires some wait to pass, for example.

# IMPORTING

Test::Retry exports one function, namely `retry_test`.

Options below are available when you `use` this module:

- max => $n

    The maximum count of retries. Affects the exported `retry_test` function.

    Defaults to $Test::Retry::MAX\_RETRIES = 5.

- delay => $floating\_secs

    The floating seconds after which the next block execution is tried after a failed test.
    Affects the exported `retry_test` function.

    Defaults to $Test::Retry::RETRY\_DELAY = 0.5.

- override => \\@function\_names

    Calls `override` (see below) at the timing of `import`.

# FUNCTIONS/METHODS

- retry\_test { ... }

    Makes the given block of code re-run if a test inside it is going to fail.
    Retry limit and interval are configurable by importing arguments (see above).

    If the test continues to fail and retry count hits the limit, the test really fails.

- Test::Retry->override(@function\_names);

    Overrides the existing test functions in caller package by retrying version of them.

    Should be called in BEGIN block for prototyping issues.

    Arguments must be passed by a coderef that returns arguments passed to the test function.

    For example,

        like $io->get(), qr/blahblah/, 'blah';

    becomes:

        BEGIN { Test::Retry->override('like') }
        
        like { $io->get(), qr/blahblah/, 'blah' };

    Pretty, heh?

# AUTHOR

motemen <motemen@gmail.com>

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
