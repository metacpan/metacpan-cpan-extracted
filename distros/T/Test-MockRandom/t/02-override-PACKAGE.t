# Testing Test::MockRandom
use strict;

use Test::More tests => 25;

#--------------------------------------------------------------------------#
# Test non-object functionality
#--------------------------------------------------------------------------#

use Test::MockRandom __PACKAGE__;

for (qw ( rand srand oneish )) {
    can_ok( __PACKAGE__, $_ );
}

is( oneish(), ( 2**32 - 1 ) / ( 2**32 ), 'is oneish nearly one' );
is( rand(), 0, 'is uninitialized call to rand() equal to zero' );

eval { srand(1) };
ok( $@, 'does srand die if argument is equal to one' );
eval { srand(1.1) };
ok( $@, 'does srand die if argument is greater than one' );
eval { srand(-0.1) };
ok( $@, 'does srand die if argument is less than zero' );

eval { srand(0) };
is( $@, q{}, 'does srand(0) live' );
eval { srand(oneish) };
is( $@, q{}, 'does srand(oneish) live' );

srand();
is( rand(), 0, 'testing srand() gives rand() == 0' );

srand(oneish);
is( rand(), oneish, 'testing srand(oneish) gives rand == oneish' );

srand(.5);
is( rand(), .5, 'testing srand(.5) gives rand == .5' );

srand(0);
is( rand(), 0, 'testing srand(0) gives rand == 0' );

srand( oneish, .3, .2, .1 );
ok( 1, 'setting srand(oneish,.3, .2, .1)' );
is( rand(), oneish, 'testing rand == oneish' );
is( rand(), .3,     'testing rand == .3' );
is( rand(), .2,     'testing rand == .2' );
is( rand(), .1,     'testing rand == .1' );
is( rand(), 0,      'testing rand == 0 (nothing left in srand array' );

#--------------------------------------------------------------------------#
# Test rand(N) functionality
#--------------------------------------------------------------------------#

srand( 0.5, 0.25, .1, 0.6 );
ok( 1, 'setting srand( 0.5, 0.25 )' );
is( rand(2),   1,    'testing rand(2) == 1' );
is( rand(0),   0.25, 'testing rand(0) == 0.25' );
is( rand(-1),  -0.1, 'testing rand(-1) == -0.1' );
is( rand('a'), 0.6,  'testing rand("a") == 0.6' );

