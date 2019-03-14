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
   $ti->use_ok('Config','xxxx','forbid'); 
   $ti->use_ok('Storable',7.01,'dclone','forbid');
}
$ti->done_testing();

