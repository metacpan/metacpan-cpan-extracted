# Test::MockRandom
use strict;

use Test::More tests => 1;

#--------------------------------------------------------------------------#
# Test package overriding
#--------------------------------------------------------------------------#

eval {
    require Test::MockRandom;
    Test::MockRandom->import(
        { bogus => [ { 'OverrideTest' => 'random' }, 'AnotherOverride' ], } );
};
ok( $@, "Does custom import spec croak on unrecognized symbol?" );

