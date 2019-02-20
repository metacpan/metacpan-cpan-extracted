#!perl

use strict;
use warnings;

use Test::More 'no_plan';
use Test::Differences;

my $got = join '' => 1..40;

TODO: {
    local $TODO = 'Testing diff styles';
    table_diff;
    eq_or_diff $got, "-$got", 'table diff';
    unified_diff;
    eq_or_diff $got, "-$got", 'unified diff';
    context_diff;
    eq_or_diff $got, "-$got", 'context diff';
    oldstyle_diff;
    eq_or_diff $got, "-$got", 'oldstyle diff';
}
