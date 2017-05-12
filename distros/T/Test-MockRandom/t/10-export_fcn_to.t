# Test::MockRandom
use strict;

use Test::More tests => 5;

#--------------------------------------------------------------------------#
# Test package overriding
#--------------------------------------------------------------------------#

use Test::MockRandom;

BEGIN {
    Test::MockRandom->export_rand_to('OverrideTest');
    Test::MockRandom->export_srand_to('OverrideTest');
    Test::MockRandom->export_oneish_to('OverrideTest');
}

eval { Test::MockRandom::export_rand_to('bogus') };
ok( $@, "Dies when export_*_to not called as class function" );
eval { Test::MockRandom->export_rand_to() };
ok( $@, "Dies when export_*_to not given an argument" );

can_ok( 'OverrideTest', qw ( rand srand oneish ) );
OverrideTest::srand( .5, OverrideTest::oneish );
is( OverrideTest::rand(), .5, 'testing OverrideTest::srand(.5)' );
is( OverrideTest::rand(), OverrideTest::oneish,
    'testing OverrideTest::srand(OverrideTest::oneish)' );

