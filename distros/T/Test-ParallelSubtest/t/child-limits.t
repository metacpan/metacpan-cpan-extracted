# Test the limit on the number of kids to run at once.

use strict;
use warnings;

use Test::ParallelSubtest tests => 6, max_parallel => 1;
use Test::More;

my $start = time();

for my $i (1 .. 5) {
    bg_subtest "subtest $i" => sub {
        sleep 1;
        is 1, 1, "1 is 1 in child $$";
        done_testing;
    };
}

my $took = time() - $start;

ok $took >= 4, 'first 4 subtests run in sequence';

