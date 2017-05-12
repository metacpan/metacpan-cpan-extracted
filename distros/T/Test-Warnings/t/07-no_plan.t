use strict;
use warnings;

# we intended to insert a test at END time whenever:
# - done_testing has not been run,
# - AND ':no_end_test' is not imported,
# - AND EITHER at least one test has been run, OR there was a plan.

# before v0.003, these last two conditions were also ANDed, so we
# never got a test added when we were running tests without a plan
# and terminated without done_testing (such as terminating a forked
# process).

use Test::More 'no_plan';

# define our END block first, so it is run last (after TW's END)
END {
    final_tests();
}

use Test::Warnings;

pass('this is a passing test');

# now we "END"...

sub final_tests
{
    is(
        Test::Builder->new->current_test, 2,
        'two tests have been run (the pass, and our no-warnings-via-END test)',
    );
}

