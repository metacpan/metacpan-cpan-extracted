# Test::MockRandom
use strict;

use Test::More tests => 3;

#--------------------------------------------------------------------------#
# Test package overriding
#--------------------------------------------------------------------------#

use Test::MockRandom;

BEGIN {
    Test::MockRandom->export_rand_to( 'OverrideTest' => 'random' );
    Test::MockRandom->export_srand_to( 'OverrideTest' => 'seed' );
    Test::MockRandom->export_oneish_to( 'OverrideTest' => 'nearly_one' );
}

can_ok( 'OverrideTest', qw ( random seed nearly_one ) );
OverrideTest::seed( .5, OverrideTest::nearly_one );
is( OverrideTest::random(), .5, 'testing OverrideTest::seed(.5)' );
is( OverrideTest::random(), OverrideTest::nearly_one,
    'testing OverrideTest::seed(OverrideTest::nearly_one)' );

