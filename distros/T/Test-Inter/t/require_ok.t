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

$ti->require_ok('5.001');
$ti->require_ok('7.001','forbid');
$ti->require_ok('Config');
$ti->require_ok('Xxx::Yyy','forbid');
$ti->require_ok('Symbol','feature');
$ti->require_ok('Xxx::Zzz','feature');

$ti->done_testing();

