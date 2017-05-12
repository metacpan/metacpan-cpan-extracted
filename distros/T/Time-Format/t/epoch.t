#!/perl -I..

# Test epoch-time formatting.
# Based on a bug report by Adam Schneider, 11 June 2009

use strict;
use Test::More;

BEGIN { $Time::Format::NOXS = 1 }
use Time::Format;

my @test_inputs =
    (
     100000000,
      99999999,
      10000000,
       9999999,
       1000000,
        999999,
    );

plan tests => scalar @test_inputs;

my $tnum = 0;
foreach my $epoch (@test_inputs)
{
    my @t = localtime $epoch;
    $t[4]++;
    $t[5] += 1900;
    my $expected = sprintf '%04d/%02d/%02d %02d:%02d:%02d', @t[5,4,3, 2,1,0];

    eval {is time_format('yyyy/mm/dd hh:mm:ss', $epoch), $expected, "Test case $tnum"} ;
    ++$tnum;
}
