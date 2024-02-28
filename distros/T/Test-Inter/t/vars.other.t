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
my $ti = new Test::Inter $0,('use_lib' => 'on') ;

$ti->is  ( 1,1, "Good test");
$ti->is  ( 2,2, "Good test");

$ti->done_testing();

