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

   $ti->use_ok('5.004');
   $ti->use_ok('Config'); 
   $ti->use_ok('Xxx::Yyy','forbid');
   $ti->use_ok('Symbol','feature'); 
   $ti->use_ok('Xxx::Zzz','feature'); 
   $ti->use_ok('Storable',1.01);
}
$ti->done_testing();

