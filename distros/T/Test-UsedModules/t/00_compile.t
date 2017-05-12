#!perl

use strict;
use warnings;

use Test::More;

use_ok $_ for qw(
    Test::UsedModules
);
diag( "Testing Test::UsedModules $Test::UsedModules::VERSION" );

done_testing;
