# Test switching off fork() usage with max_parallel => 0

use strict;
use warnings;

use t::MyTest;
use Test::More;
use Test::ParallelSubtest tests => 3, max_parallel => 0;

my $parent_variable = 0;

my $ret = bg_subtest foo => sub {
    plan tests => 1;
    ok 1, "subtest running";
    $parent_variable = $$;
};

is $parent_variable, $$, "bg_subtest() did not fork";

ok $ret, "bg_subtest returned passing subtest() status when not forking";

