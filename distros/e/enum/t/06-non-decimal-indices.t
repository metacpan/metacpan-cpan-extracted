#!perl

use strict;
use warnings;

use Test::More 0.88 tests => 3;

use enum qw(EIGHT=010 FIFTEEN=0xf THOUSAND=1_000);

ok(EIGHT    == 8,    "EIGHT should equal 8");
ok(FIFTEEN  == 15,   "FIFTEEN should equal 15");
ok(THOUSAND == 1000, "THOUSAND should equal 1000");

