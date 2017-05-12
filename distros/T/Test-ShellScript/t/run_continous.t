#!/usr/bin/perl

use 5.008000;
use strict;
use warnings;
use Test::ShellScript;

require('t/lib/Internal.pm');
run_ok(Internal::getCmdLine(), "^TEST:");

### --- continuous time flow mode
reset_timeline();
variable_ok("executed", "false");
variable_ok("executed", "true");

reset_timeline();
variable_ok("params", "echo");
variable_ok("executed", "false");
variable_ok("executed", "true");
variable_ok("output", "0");
