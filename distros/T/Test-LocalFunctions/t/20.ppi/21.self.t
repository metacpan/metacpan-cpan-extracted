#!perl

use strict;
use warnings;
use utf8;

use Test::LocalFunctions::PPI;

use Test::More;

$ENV{TEST_LOCALFUNCTIONS_TEST_PHASE} = 1;
all_local_functions_ok();

done_testing;
