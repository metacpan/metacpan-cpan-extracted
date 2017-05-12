#!/usr/bin/perl

# Test that we can control the randomness of the code.

use strict;
use warnings;

use Test::More;

BEGIN {
    # Anything, so long as its the same.
    $ENV{TEST_RANDOM_SEED} = 12345;
}

my $have = `$^X "-Ilib" t/rand_check.plx`;
my $want = `$^X "-Ilib" t/rand_check.plx`;

like $have, qr/^\d+$/, "got sensible output";
is $have, $want, "Can control randomness with TEST_RANDOM_SEED";

done_testing(2);
