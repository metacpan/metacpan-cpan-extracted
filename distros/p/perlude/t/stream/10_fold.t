#! /usr/bin/perl
use strict;
use warnings;
use Test::More;
use Perlude;

my @tests =
( []
, [undef] 
, [1..10] 
, ['']
, ["haha"]
);

plan tests => 3*@tests;

for my $t (@tests) {
    is_deeply
    ( [fold unfold @$t]
    , $t
    , "fold unfold => id"
    )
}

# fold in void context
for my $t (@tests) {
    my @l = @$t;
    my $n = 1+@l;
    #fold apply { $n--; @_ } unfold @$t;
    fold sub { $n--; @l ? (shift @l) : () };
    is $n, 0, (0+@$t)." elements in void context";
}

# fold in scalar context
for my $t (@tests) {
    my $n = fold unfold @$t;
    is $n, 0+@$t, (0+@$t)." elements in scalar context";
}

