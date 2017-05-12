use strict;
use warnings;

use Test::More 0.88;
use Test::Warnings;

# testing our alteration of done_testing is a bit tricky, as (duh) once we've
# called done_testing, we're done and cannot emit any further TAP.  Therefore,
# I'll do post-done_testing tests simply by diagnostics and via the exit code,
# which should be enough for cpantesters to generate a failure report.

pass('a passing test');

my $tb = Test::Builder->new;

is($tb->current_test, 1, 'we have had one test so far');

# now our test count is 2

done_testing;

# now our test count should be 3, and we cannot call any more test functions

my $tests = $tb->current_test;
if ($tests != 3)
{
    note 'test count not ok - is ' . $tests . ', should be 3!';
    exit 1;
}

note 'test count ok!';

