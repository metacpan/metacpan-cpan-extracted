#! /usr/bin/perl
use strict;
use warnings;
use Perlude::Lazy;
use Test::More;

plan tests => 2;


my ( @input, $got, $expected );

my $doubles = do {
    my $seed = 0;
    enlist { $seed+=2 }
};

my @first  = fold takeWhile { $_ < 5 } $doubles;
is_deeply \@first, [2, 4];

$TODO = 'dolmen says this test is broken';

my ($next) = fold take 1, $doubles;
is $next, 6;
