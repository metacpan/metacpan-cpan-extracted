use strict;
use warnings;

use Test::More tests => 1;  # avoid our done_testing hook

END {
    final_tests();
}

use Test::Warnings ':no_end_test';
use if "$]" >= '5.008', lib => 't/lib';
use if "$]" >= '5.008', 'SilenceStderr';

warn 'this warning is not expected to be caught';

pass 'a passing test, to keep the harness happy';

# this is run in the END block
sub final_tests
{
    # if there was anything else than 1 test run, then we will fail
    exit (Test::Builder->new->current_test <=> 1);
}
