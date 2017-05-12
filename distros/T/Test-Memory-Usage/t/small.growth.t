#!perl
use strict;
use warnings;

use Test::Most;
use Test::Builder::Tester;
use Test::Memory::Usage;

my @thingy;
for (1 .. 150) {
    push @thingy, [ $_ ];
}

# test the output from our tests
test_out(
    'ok 1 - array has elements',
    'ok 2 - virtual memory usage grows less than 20%',
    'ok 3 - RSS memory usage grows less than 20%',
    'ok 4 - data/stack memory usage grows less than 20%',
);

ok(@thingy, 'array has elements');
memory_usage_ok(20);

test_test( skip_err => 1, title => 'tests emit expected output');

# fin
done_testing;

