#!perl

use strict;
use warnings;
use Test::More 0.88 tests => 3;

my $maxint;
my $maxint_without_top_bit;

BEGIN {
    $maxint = ~0;
    $maxint_without_top_bit = ~0;
    $maxint_without_top_bit >> 1;
}

eval qq{use enum "BITMASK:A=$maxint", 'B', 'C', 'D';};
ok(defined($@) && $@ =~ m!not a valid single bitmask!,
   "Starting a bitmask sequence at maxint should error on wrap-around");

eval qq{use enum "BITMASK:MASK_=$maxint", 'X', 'Y', 'Z';};
ok(defined($@) && $@ =~ m!not a valid single bitmask!,
   "Bitmask, with prefix, and maxint wraparound");

eval qq{use enum "BITMASK:MASK_=$maxint_without_top_bit", 'X', 'Y', 'Z';};
ok(defined($@) && $@ =~ m!not a valid single bitmask!,
   "Bitmask, where second symbol will become maxint");

