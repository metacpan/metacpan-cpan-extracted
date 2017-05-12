#!perl

use strict;
use warnings;
use Test::LocalFunctions::PPI;

use Test::More;

no strict 'subs';
can_ok( Test::LocalFunctions::PPI, qw/all_local_functions_ok local_functions_ok/ );
use strict;

done_testing;
