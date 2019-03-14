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

$ti->skip_all("testing skip_all");
$ti->plan(3);
$ti->_ok("Test 1");
$ti->diag("Test 1 diagnostic message");
$ti->_ok("Test 2");
$ti->_ok("Test 3");
