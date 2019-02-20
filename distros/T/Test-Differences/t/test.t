#!perl

use strict;
use warnings;
use Test::More;
use Test::Differences;

my @tests = (
    sub { eq_or_diff "a",               "b" },
    sub { eq_or_diff "a\nb\nc\n",       "a\nc\n" },
    sub { eq_or_diff "a\nb\nc\n",       "a\nB\nc\n" },
    sub { eq_or_diff "a\nb\nc\nd\ne\n", "a\nc\ne\n" },
    sub { eq_or_diff "a\nb\nc\nd\ne\n", "a\nb\nd\ne\n", { context => 0 } },
    sub { eq_or_diff "a\nb\nc\nd\ne\n", "a\nb\nd\ne\n", { context => 10 } },
);

plan tests => scalar @tests;
diag "This test misuses TODO: these TODOs are actually real tests.\n";

TODO: {
    local $TODO = 'Deliberate misuse of TODO';
    $_->() for @tests;
}
