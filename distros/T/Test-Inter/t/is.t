#!/usr/bin/perl

use warnings 'all';
use strict;
BEGIN {
   if (-d "lib") {
      use lib "./lib";
   } elsif (-d "../lib") {
      use lib "../lib";
   }
}

use Test::Inter;
my $ti = new Test::Inter $0;

$ti->is  ( [ 'a','b' ], [ 'a','b' ], "List test" );
$ti->isnt( [ 'a','b' ], [ 'a','c' ], "List test" );

$ti->is  ( { 'a' => 1, 'b' => 2 }, { 'a' => 1, 'b' => 2 }, "Hash test" );
$ti->isnt( { 'a' => 1, 'b' => 2 }, { 'a' => 1, 'b' => 3 }, "Hash test" );

$ti->done_testing();

