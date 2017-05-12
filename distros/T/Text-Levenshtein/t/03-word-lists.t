#!perl

use strict;
use warnings;
use Test::More 0.88;
use Text::Levenshtein qw/ distance /;

my @TESTS = (
    ['pink', ['pink', 'pine', 'pork', ''], [0, 1, 2, 4]],
    ['',     [' ', '', '42', 'marvin'],    [1, 0, 2, 6]],
);

plan tests => int(@TESTS);

foreach my $test (@TESTS) {
    my ($word, $listref, $resultref) = @$test;
    my @results = distance($word, @$listref);
    is_deeply(\@results, $resultref);
}
