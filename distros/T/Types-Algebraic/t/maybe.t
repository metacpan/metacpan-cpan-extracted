#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 1;

use Types::Algebraic;

data Maybe = Nothing | Just :v;

my $sum = 0;
my @vs = ( Nothing, Just(5), Just(7), Nothing, Just(6) );
for my $v (@vs) {
    match ($v) {
        with (Nothing) { }
        with (Just $v) { $sum += $v; }
    }
}

is($sum, 18, 'Got correct sum from adding together maybes.');
