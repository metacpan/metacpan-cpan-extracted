#! /usr/bin/perl
use 5.10.0;
use strict;
use warnings;
use Perlude;
use Test::More skip_all => 'this is not fixable';

my ( @input, $got, $expected );

my $doubles = sub {
    state $seed = 0;
    $seed+=2;
};

my @first  = fold takeWhile { $_ < 5 } $doubles;
is_deeply \@first, [2, 4];

$TODO = 'dolmen says this test is broken';

my ($next) = fold take 1, $doubles;
is $next, 6;
