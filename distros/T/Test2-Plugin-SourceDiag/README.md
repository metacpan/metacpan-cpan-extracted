# NAME

Test2::Plugin::SourceDiag - Output the lines of code that resulted in a
failure.

# DESCRIPTION

This plugin injects diagnostics messages that include the lines of source that
executed to produce the test failure. This is a less magical answer to Damian
Conway's [Test::Expr](https://metacpan.org/pod/Test%3A%3AExpr) module, that has the benefit of working on any Test2
based test.

# SYNOPSIS

This test:

    use Test2::V0;
    use Test2::Plugin::SourceDiag;

    ok(0, "fail");

    done_testing;

Produces the output:

    not ok 1 - fail
    Failure source code:
    # ------------
    # 4: ok(0, "fail");
    # ------------
    # Failed test 'fail'
    # at test.pl line 4.

# IMPORT OPTIONS

## show\_source

    use Test2::Plugin::SourceDiag show_source => $bool;

`show_source` is set to on by default. You can specify `0` if you want to
turn it off.

Source output:

    not ok 1 - fail
    Failure source code:
    # ------------
    # 4: ok(0, "fail");
    # ------------
    # Failed test 'fail'
    # at test.pl line 4.

## show\_args

    use Test2::Plugin::SourceDiag show_args => $bool

`show_args` is set to off by default. You can turn it on with a true value.

Args output:

    not ok 1 - fail
    Failure source code:
    # ------------
    # 4: ok($x, "fail");
    # ------------
    # Failure Arguments: (0, 'fail')      <----- here
    # Failed test 'fail'
    # at test.pl line 4.

## inject\_name

    use Test2::Plugin::SourceDiag inject_name => $bool

`inject_name` is off by default. You may turn it on if desired.

This feature will inject the source as the name of your assertion if the name
has not already been set. When this happens the failure source diag will not be
seen as the name is sufficient.

    not ok 1 - ok($x eq $y);
    # Failed test 'ok($x eq $y);'
    # at test.pl line 4.

**note:** This works perfectly fine with multi-line statements.

# SOURCE

The source code repository for Test2-Plugin-SourceDiag can be found at
`http://github.com/Test-More/Test2-Plugin-SourceDiag/`.

# MAINTAINERS

- Chad Granum <exodist@cpan.org>

# AUTHORS

- Chad Granum <exodist@cpan.org>

# COPYRIGHT

Copyright 2017 Chad Granum <exodist@cpan.org>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See `http://dev.perl.org/licenses/`
