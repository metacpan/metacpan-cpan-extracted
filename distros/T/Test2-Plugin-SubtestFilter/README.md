[![Actions Status](https://github.com/kfly8/Test2-Plugin-SubtestFilter/actions/workflows/test.yml/badge.svg?branch=main)](https://github.com/kfly8/Test2-Plugin-SubtestFilter/actions?workflow=test) [![MetaCPAN Release](https://badge.fury.io/pl/Test2-Plugin-SubtestFilter.svg)](https://metacpan.org/release/Test2-Plugin-SubtestFilter)
# NAME

Test2::Plugin::SubtestFilter - Filter subtests by name

# SYNOPSIS

```perl
# t/test.t
use Test2::V0;
use Test2::Plugin::SubtestFilter;

subtest 'foo' => sub {
    ok 1;
    subtest 'bar' => sub { ok 1 };
};

subtest 'baz' => sub {
    ok 1;
};

done_testing;
```

Then run with filtering:

```perl
# Run only 'foo' subtest and all its children
$ SUBTEST_FILTER=foo prove -lv t/test.t

# Run nested 'bar' subtest (and its parent 'foo')
$ SUBTEST_FILTER=bar prove -lv t/test.t

# Use regex patterns
$ SUBTEST_FILTER='ba' prove -lv t/test.t  # Matches 'bar' and 'baz'

# Run all tests (no filtering)
$ prove -lv t/test.t
```

# DESCRIPTION

Test2::Plugin::SubtestFilter is a Test2 plugin that allows you to selectively run
specific subtests based on environment variables. This is useful when you want to
run only a subset of your tests during development or debugging.

# FILTERING BEHAVIOR

The plugin matches subtest names using partial matching (substring or regex pattern).
For nested subtests, the full name is constructed by joining parent and child names
with spaces.

## How Matching Works

- **Simple match**

    ```perl
    subtest 'foo' => sub { ... };
    # SUBTEST_FILTER=foo matches 'foo'
    # SUBTEST_FILTER=fo  matches 'foo' (partial match)
    ```

- **Nested subtest match**

    ```perl
    subtest 'parent' => sub {
        subtest 'child' => sub { ... };
    };
    # Full name is: 'parent child'
    # SUBTEST_FILTER=child         matches 'parent child'
    # SUBTEST_FILTER='parent child' matches 'parent child'
    ```

- **When parent matches**

    When a parent subtest matches the filter, ALL its children are executed.

    ```perl
    SUBTEST_FILTER=parent prove -lv t/test.t
    # Executes 'parent' and all nested subtests inside it
    ```

- **When child matches**

    When a nested child matches the filter, its parent is executed but only the
    matching children run. Non-matching siblings are skipped.

    ```
    SUBTEST_FILTER=child prove -lv t/test.t
    # Executes 'parent' (to reach 'child') but skips other children
    ```

- **No match**

    Subtests that don't match the filter are skipped.

- **No filter set**

    When `SUBTEST_FILTER` is not set, all tests run normally.

# ENVIRONMENT VARIABLES

- `SUBTEST_FILTER`

    Regular expression pattern for partial matching against subtest names.
    Supports both substring matching and full regex patterns.

    ```perl
    SUBTEST_FILTER=foo      # Matches 'foo', 'foobar', 'my foo test', etc.
    SUBTEST_FILTER='foo.*'  # Matches 'foo', 'foobar', 'foo_test', etc.
    SUBTEST_FILTER='foo|bar' # Matches 'foo' or 'bar'
    ```

# CAVEATS

- This plugin must be loaded AFTER Test2::V0 or Test2::Tools::Subtest,
as it needs to override the `subtest` function that they export.
- The plugin modifies the `subtest` function in the caller's namespace,
which may interact unexpectedly with other code that also modifies `subtest`.

# SEE ALSO

- [Test2::V0](https://metacpan.org/pod/Test2%3A%3AV0) - Recommended Test2 bundle
- [Test2::Tools::Subtest](https://metacpan.org/pod/Test2%3A%3ATools%3A%3ASubtest) - Core subtest functionality
- [Test2::API](https://metacpan.org/pod/Test2%3A%3AAPI) - Test2 API for intercepting events

# LICENSE

Copyright (C) kobaken.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

kobaken <kentafly88@gmail.com>
