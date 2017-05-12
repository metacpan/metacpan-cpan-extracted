#!/usr/bin/env perl -l
use warnings;
use strict;
use callee;
use Test::More;
my $fib = sub {
    my $x = shift;
    return 0 if $x == 0;
    return 1 if $x == 1;
    callee->($x - 1) + callee->($x - 2);
};
my @expect = (0, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89);
plan tests => scalar @expect;
for (0 .. $#expect) {
    my $got = $fib->($_);
    is($got, $expect[$_], "fib($_) = $got");
}
