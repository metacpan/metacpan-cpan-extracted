#!perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;
use Test::UsedModules;

all_used_modules_ok();

done_testing;
