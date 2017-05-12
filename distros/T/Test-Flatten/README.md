[![Build Status](https://travis-ci.org/xaicron/p5-Test-Flatten.svg?branch=master)](https://travis-ci.org/xaicron/p5-Test-Flatten)
# NAME

Test::Flatten - subtest output to a flatten

# SYNOPSIS

in t/foo.t

    use Test::More;
    use Test::Flatten;

    subtest 'foo' => sub {
        pass 'OK';
    };
    
    subtest 'bar' => sub {
        pass 'ok';
        subtest 'baz' => sub {
            pass 'ok';
        };
    };

    done_testing;

run it

    $ prove -lvc t/foo.t
    t/foo.t .. 
    # ------------------------------------------------------------------------------
    # foo
    # ------------------------------------------------------------------------------
    ok 1 - ok
    # ------------------------------------------------------------------------------
    # bar
    # ------------------------------------------------------------------------------
    ok 2 - ok
    # ------------------------------------------------------------------------------
    # baz
    # ------------------------------------------------------------------------------
    ok 3 - ok
    1..3
    ok

oh, flatten!

# DESCRIPTION

Test::Flatten is override Test::More::subtest.

The subtest I think there are some problems.

- 1. Caption is appears at end of subtest block.

        use Test::More;

        subtest 'foo' => sub {
            pass 'ok';
        };

        done_testing;

        # ok 1 - foo is end of subtest block.
        t/foo.t .. 
            ok 1 - ok
            1..1
        ok 1 - foo
        1..1
        ok

    I want __FIRST__.

- 2. Summarizes the test would count.

        use Test::More;

        subtest 'foo' => sub {
            pass 'bar';
            pass 'baz';
        };

        done_testing;

        # total tests is 1
        t/foo.t .. 
            ok 1 - bar
            ok 2 - baz
            1..2
        ok 1 - foo
        1..1

    I want __2__.

- 3. Forked test output will be broken. (Even with Test::SharedFork!)

        use Test::More;
        
        subtest 'foo' => sub {
            pass 'parent one';
            pass 'parent two';
            my $pid = fork;
            unless ($pid) {
                pass 'child one';
                pass 'child two';
                fail 'child three';
                exit;
            }
            wait;
            pass 'parent three';
        };
        
        done_testing;

        # success...?
        t/foo.t .. 
            ok 1 - parent one
            ok 2 - parent two
            ok 3 - child one
            ok 4 - child two
            not ok 5 - child three
            
            #   Failed test 'child three'
            #   at t/foo.t line 13.
            ok 3 - parent three
            1..3
        ok 1 - foo
        1..1
        ok

    oh, really? I want __FAIL__ and sync count.

Yes, We can!!

# FUNCTIONS 

- `subtest($name, \&code)`

    This like Test::More::subtest.

# SUBTEST\_FILTER

If you need, you can using `SUBTEST_FILTER` environment.
This is just a __\*hack\*__ to skip only blocks matched the block name by environment variable.
`SUBTEST_FILTER` variable can use regexp

    $ env SUBTEST_FILTER=foo prove -lvc t/bar.t
    # SKIP: bar by SUBTEST_FILTER
    # ------------------------------------------------------------------------------
    # foo
    # ------------------------------------------------------------------------------
    ok 1 - passed
    # SKIP: baz by SUBTEST_FILTER
    1..1

# AUTHOR

xaicron <xaicron {at} cpan.org>

# COPYRIGHT

Copyright 2011 - xaicron

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# SEE ALSO

[Test::SharedFork](https://metacpan.org/pod/Test::SharedFork)
