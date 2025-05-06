# NAME

Test2::Plugin::DBBreak - Automatic breakpoint on failing tests for the perl debugger

# DESCRIPTION

This plugin will automatically break when a test running in the perl
debugger fails.

# SYNOPSIS

This test:

    use Test2::V0;
    use Test2::Plugin::DBBreak;

    ok(0, "fail");

    done_testing;

Produces the output:

    not ok 1 - fail
    Test2::Plugin::DBBreak::listener(/usr/local/lib/perl5/site_perl/5.36.1/Test2/Plugin/DBBreak.pm:29):
    29:         return;

# OPTIONS

To disable the breakpoint temporarily, set the $disable variable to 1:

    $Test2::Plugin::DBBreak::disable = 1

# SOURCE

The source code repository for Test2-Plugin-DBBreak can be found at
`https://github.com/kcaran/Test2-Plugin-DBBreak/`.

# MAINTAINERS

- Keith Carangelo <kcaran@gmail.com>

# AUTHORS

- Keith Carangelo <kcaran@gmail.com>

# COPYRIGHT

Copyright 2025 Keith Carangelo <kcaran@gmail.com>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See `https://dev.perl.org/licenses/`
