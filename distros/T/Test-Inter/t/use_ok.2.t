#!/usr/bin/perl

use warnings 'all';
use strict;
my $ti;

BEGIN {
   if (-d "lib") {
      use lib "./lib";
   } elsif (-d "../lib") {
      use lib "../lib";
   }

   use Test::Inter;
   $ti = new Test::Inter $0;

   $ti->use_ok('7.001','forbid'); 
   $ti->use_ok('Config','myconfig'); 
   $ti->use_ok('Storable',1.01,'dclone'); 
}
$ti->done_testing();

