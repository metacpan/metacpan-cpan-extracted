#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use Test::MemoryGrowth;

my $count;

$count = 0;
no_growth { $count++ };
is( $count, 10010, '$count == 10010 after defaults' );

$count = 0;
no_growth { $count++ } burn_in => 5, calls => 5;
is( $count, 10, '$count == 10 after burn_in=5, calls=5' );

done_testing;
