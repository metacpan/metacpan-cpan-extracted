#!perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;
use Test::UsedModules;

used_modules_ok("lib/Test/UsedModules.pm");

done_testing;
