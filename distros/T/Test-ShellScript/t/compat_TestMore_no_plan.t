#!/usr/bin/perl

use 5.008000;
use strict;
use warnings;
use Test::ShellScript;
use Test::More;

require('t/lib/Internal.pm');

my $testNUmber = 1;
### --- step by step mode
run_ok(Internal::getCmdLine(), "^TEST:");
$testNUmber++;
isCurrentVariable("params");

### using Test::More
ok($testNUmber == 2);

### Back again to Test::ShellScript !!!
isCurrentValue("echo");
