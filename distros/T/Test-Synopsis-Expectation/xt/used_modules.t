#!perl

use strict;
use warnings;
use Test::More;

eval {
    require Test::UsedModules;
};
plan skip_all => "Test::UsedModules required for testing variables" if $@;

Test::UsedModules::all_used_modules_ok();
