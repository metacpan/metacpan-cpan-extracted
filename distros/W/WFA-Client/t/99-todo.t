#!/usr/bin/env perl -T

use strict;
use warnings;

use Test::More;

TODO: {
    local $TODO = 'unimplemented features';

    ok(undef, 'test $job->poll_for_completion()');
    ok(undef, 'implement and test error handling');
    ok(undef, 'poll_for_completion should take timeout');
}

done_testing();
