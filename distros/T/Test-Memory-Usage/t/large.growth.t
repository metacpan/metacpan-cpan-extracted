#!perl
use strict;
use warnings;

use Test::Most;
use Test::Builder::Tester;
use Test::Memory::Usage;

# set up and chuck some data into a variable
my @thingy;
for (1 .. 150_000) {
    push @thingy, [ $_ ];
}

# mark the current state as the point in time we care about
memory_usage_start;

# fill out the variable even more
for (1 .. 450_000) {
    push @thingy, [ $_ ];
}

# test the output from our tests
test_out(
    'ok 1 - array has elements',
    'not ok 2 - virtual memory usage grows less than 20%',
    'not ok 3 - RSS memory usage grows less than 20%',
    'not ok 4 - data/stack memory usage grows less than 20%',
);
test_fail(+3);

ok(@thingy, 'array has elements');
memory_usage_ok(20);

test_test( skip_err => 1, title => 'tests emit expected output');

# fin
done_testing;

# example moutput from test run (where we expect tests to fail!)
#   [5200][c.wright@fulcrum-chz:test-memory-usage][master⚡]➔ prove -lrv t/test.memory.usage.large.growth.t 
#   t/test.memory.usage.large.growth.t .. 
#   ok 1 - array has elements
#   not ok 2 - virtual memory usage grows less than 20%
#   
#   #   Failed test 'virtual memory usage grows less than 20%'
#   #   at /home/c.wright/development/test-memory-usage/lib/Test/Memory/Usage.pm line 75.
#   # virtual memory usage grew from 103452 to 173300 (167.5%)
#   not ok 3 - RSS memory usage grows less than 20%
#   
#   #   Failed test 'RSS memory usage grows less than 20%'
#   #   at /home/c.wright/development/test-memory-usage/lib/Test/Memory/Usage.pm line 79.
#   # RSS memory usage grew from 29908 to 99804 (333.7%)
#   1..3
#   # Looks like you failed 2 tests of 3.
#   Dubious, test returned 2 (wstat 512, 0x200)
#   Failed 2/3 subtests 
#   
#   Test Summary Report
#   -------------------
#   t/test.memory.usage.large.growth.t (Wstat: 512 Tests: 3 Failed: 2)
#     Failed tests:  2-3
#     Non-zero exit status: 2
#   Files=1, Tests=3,  1 wallclock secs ( 0.02 usr  0.00 sys +  0.24 cusr  0.13 csys =  0.39 CPU)
#   Result: FAIL
