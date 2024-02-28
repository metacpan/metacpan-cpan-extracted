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
my $ti = new Test::Inter ('start' => 3, 'end' => 4) ;

$ti->is  ( 1,-1, "Broken test");
$ti->is  ( 2,-2, "Broken test");

$ti->is  ( 3,3,  "Good test");
$ti->is  ( 4,4,  "Good test");

$ti->is  ( 5,-5, "Broken test");
$ti->is  ( 6,-6, "Broken test");

$ti->done_testing();

