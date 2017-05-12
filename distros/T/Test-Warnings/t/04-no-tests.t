use strict;
use warnings;

use Test::More 0.88;

# if all we do is load Test::Warnings and exit, we should not add a test at END
# time. For one thing, this lets this distribution generate a compilation test
# without trying to run a plan-less test.

# last in, first out: Test::Warnings's END will run after this one
END {
    is(Test::Builder->new->current_test, 0, 'no tests run during END');

    # might as well throw this in for good measure ;)
    done_testing;
}

use Test::Warnings;

