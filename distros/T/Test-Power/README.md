# NAME

Test::Power - With great power, comes great responsibility.

# SYNOPSIS

    use Test::Power;

    sub foo { 4 }
    expect { foo() == 3 };
    expect { foo() == 4 };

Output:

    not ok 1 - L12 : expect { foo() == 3 };
    #   Failed test 'L12 : ok { foo() == 3 };'
    #   at foo.pl line 12.
    # foo()
    #    => 4
    ok 2 - L13 : expect { foo() == 4 };
    1..2
    # Looks like you failed 1 test of 2.

# DESCRIPTION

__WARNINGS: This module is currently on ALPHA state. Any APIs will change without notice. Notice that since this module uses the B power, it may cause segmentation fault.__

__WARNINGS AGAIN: Current version of Test::Power does not support ithreads.__

Test::Power is yet another testing framework.

Test::Power shows progress data if it fails. For example, here is a testing script using Test::Power. This test may fail.

    use Test::Power;

    sub foo { 3 }
    expect { foo() == 2 };
    done_testing;

Output is:

    not ok 1 - L6: expect { foo() == 2 };
    # foo()
    #    => 3
    1..1

Woooooooh! It's pretty magical. `Test::Power` shows the calculation progress! You don't need to use different functions for different testing types, like ok, cmp\_ok, is...

# EXPORTABLE FUNCTIONS

- `expect(&code)`

        expect { $foo };

    This simply runs the `&code`, and uses that to determine if the test succeeded or failed.
    A true expression passes, a false one fails.  Very simple.

# REQUIRED PERL VERSION

Perl5.14+ is required. 5.14+ provides better support for custom ops.
[B::Tap](https://metacpan.org/pod/B::Tap) required this. Under 5.14, perl5 can't do B::Deparse.

Patches welcome to support 5.12, 5.10, 5.8.

# LICENSE

Copyright (C) tokuhirom.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

tokuhirom <tokuhirom@gmail.com>

# SEE ALSO

[Test::More](https://metacpan.org/pod/Test::More)
