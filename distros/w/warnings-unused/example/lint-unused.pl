#!perl -w
# A simple module lint program
# Usage: lint-unused.pl MODULE1, MODULE2 ...

use strict;
use Module::Load;

use warnings::unused -global;

load($_) for @ARGV;
