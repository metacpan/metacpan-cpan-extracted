#!perl

use strict;
use warnings;
use Test::More;
use Test::Differences;

# use large enough data sets that this thing chooses context => 3 instead
# of "full document context".
my $x = ( "\n" x 30 ) . "x\n";
my $y = ( "\n" x 30 ) . "y\n";

my @tests = (
    sub { eq_or_diff $x,      $y },
    sub { eq_or_diff_text $x, $y },
    sub { eq_or_diff_data $x, $y },
);

plan tests => scalar @tests;

TODO: {
    local $TODO = 'Force the output to be displayed';
    $_->() for @tests;
}
