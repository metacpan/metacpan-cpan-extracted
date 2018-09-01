#!/usr/bin/perl

use 5.006;
use strict; use warnings;
use Text::MostFreqKDistance;
use Test::More tests => 16;
use Test::Exception;

throws_ok { MostFreqKHashing() }
    qr/Missing source string/, 'Caught missing source string';
throws_ok { MostFreqKHashing('x') }
    qr/Missing frequency value/, 'Caught missing frequency value';
throws_ok { MostFreqKHashing('x','y') }
    qr/Invalid frequency value/, 'Caught invalid frequency value';
throws_ok { MostFreqKHashing('x',-1) }
    qr/Invalid frequency value/, 'Caught invalid frequency value';

while (<DATA>) {
    chomp;
    my ($message, $string, $expected) = split /\|/, $_, 3;
    is(MostFreqKHashing($string, 2), $expected, $message);
}

done_testing();

__DATA__
Test 01|my|m1y1
Test 02|a|a1NULL0
Test 03|night|n1i1
Test 04|natch|n1a1
Test 05|seeking|e2s1
Test 06|research|r2e2
Test 07|aaaaabbbb|a5b4
Test 08|ababababa|a5b4
Test 09|significant|i3n2
Test 10|capabilities|i3a2
Test 11|LCLYTHIGRNIYYGSYLYSETWNTGIMLLLITMATAFMGYVLPWGQMSFWGATVITNLFSAIPYIGTNLV|L9T8
Test 12|EWIWGGFSVDKATLNRFFAFHFILPFTMVALAGVHLTFLHETGSNNPLGLTSDSDKIPFHPYYTIKDFLG|F9L8
