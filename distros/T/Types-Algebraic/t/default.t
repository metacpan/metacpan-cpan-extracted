#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 1;

use Types::Algebraic;

data Color = Red | Blue | Green | White | Black;

my $color = Blue;
my $case;

match ($color) {
    with (Red) { $case = "Red"; }
    default    { $case = "default"; }
}

is($case, "default", "Blue hits default case");
