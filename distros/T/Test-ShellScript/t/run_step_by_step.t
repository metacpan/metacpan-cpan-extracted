#!/usr/bin/perl

use 5.008000;
use strict;
use warnings;
use Test::ShellScript;

require('t/lib/Internal.pm');

### --- step by step mode
run_ok(Internal::getCmdLine(), "^TEST:");
isCurrentVariable("params");
isCurrentValue("echo");
isCurrentVariable("params");
isCurrentValue("echo");

nextSlot();
isCurrentVariable("executed");
isCurrentValue("false");

nextSlot();
isCurrentVariable("executed");
isCurrentValue("true");

nextSlot();
isCurrentVariable("output");
isCurrentValue("0");
