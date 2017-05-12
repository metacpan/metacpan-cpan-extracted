#!perl

use strict;
use warnings;
use Test::More;

eval {
    require Test::LocalFunctions;
};
plan skip_all => "Test::LocalFunctions required for testing variables" if $@;

Test::LocalFunctions::all_local_functions_ok();
