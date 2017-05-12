#!/usr/bin/perl

use 5.006;
use strict; use warnings;
use Text::MostFreqKDistance;
use Test::More tests => 6;

while (<DATA>) {
    chomp;
    my ($message, $a, $b, $k, $d, $expected) = split /\|/, $_, 6;
    is(MostFreqKSDF($a, $b, $k, $d), $expected, $message);
}

done_testing();

__DATA__
Test 01|my|a|2|10|10
Test 02|night|natch|2|10|9
Test 03|seeking|research|2|10|8
Test 04|aaaaabbbb|ababababa|2|10|1
Test 05|significant|capabilities|2|10|7
Test 06|LCLYTHIGRNIYYGSYLYSETWNTGIMLLLITMATAFMGYVLPWGQMSFWGATVITNLFSAIPYIGTNLV|EWIWGGFSVDKATLNRFFAFHFILPFTMVALAGVHLTFLHETGSNNPLGLTSDSDKIPFHPYYTIKDFLG|2|100|83
