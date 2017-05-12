#!/usr/bin/perl

use 5.008000;
use strict;
use warnings;
use Test::ShellScript;
use Test::More tests => 6;

require('t/lib/Internal.pm');

### --- step by step mode
run_ok(Internal::getCmdLine(), "^TEST:");
isCurrentVariable("params");

### using Test::More
ok(1);
isnt(1, 2, "ddddddddddd");
is (1, 1, "ssssssssss");

### Back again to Test::ShellScript !!!
isCurrentValue("echo");
