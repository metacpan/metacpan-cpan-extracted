# Trap bg_subtest() from within a child

use strict;
use warnings;

use Test::Exception;
use Test::More tests => 1;
use Test::ParallelSubtest;

bg_subtest in_a_subtest => sub {
    lives_ok {    subtest foo => \&passer } "nested subtest allowed";
    dies_ok  { bg_subtest foo => \&passer } "nested bg_subtest trapped";
    done_testing;
};

sub passer {
    ok 1;
    done_testing;
}

