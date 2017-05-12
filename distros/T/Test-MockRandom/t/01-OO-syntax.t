# Testing Test::MockRandom
use strict;

use Test::More tests => 23;

#--------------------------------------------------------------------------#
# Test object oriented functionality
#--------------------------------------------------------------------------#

use Test::MockRandom;
my $obj = Test::MockRandom->new();
isa_ok( $obj,      'Test::MockRandom', "Class constructor" );
isa_ok( $obj->new, 'Test::MockRandom', "Object constructor" );

is( $obj->rand(), 0, 'is uninitialized call to $obj->rand() equal to zero' );

eval { Test::MockRandom->new(1) };
ok( $@, 'does Test::MockRandom->new die if argument is equal to one' );
eval { Test::MockRandom->new(1.1) };
ok( $@, 'does Test::MockRandom->new die if argument is greater than one' );
eval { Test::MockRandom->new(-0.1) };
ok( $@, 'does Test::MockRandom->new die if argument is less than zero' );
eval { Test::MockRandom->new(0) };
is( $@, q{}, 'does Test::MockRandom->new(0) live' );
eval { Test::MockRandom->new(Test::MockRandom::oneish) };
is( $@, q{}, 'does Test::MockRandom->new(Test::MockRandom::oneish) live' );

eval { $obj->srand(1) };
ok( $@, 'does $obj->srand die if argument is equal to one' );
eval { $obj->srand(1.1) };
ok( $@, 'does $obj->srand die if argument is greater than one' );
eval { $obj->srand(-0.1) };
ok( $@, 'does $obj->srand die if argument is less than zero' );

eval { $obj->srand(0) };
is( $@, q{}, 'does $obj->srand(0) live' );
eval { $obj->srand( $obj->oneish ) };
is( $@, q{}, 'does $obj->srand($obj->oneish) live' );

$obj->srand();
is( $obj->rand(), 0, 'testing $obj->srand() gives $obj->rand() == 0' );

$obj->srand( $obj->oneish );
is( $obj->rand(), $obj->oneish,
    'testing $obj->srand($obj->oneish) gives $obj->rand == $obj->oneish' );

$obj->srand(.5);
is( $obj->rand(), .5, 'testing $obj->srand(.5) gives $obj->rand == .5' );

$obj->srand(0);
is( $obj->rand(), 0, 'testing $obj->srand(0) gives $obj->rand == 0' );

$obj->srand( $obj->oneish, .3, .2, .1 );
ok( 1, 'setting $obj->srand(oneish,.3, .2, .1)' );
is( $obj->rand(), $obj->oneish, 'testing $obj->rand == oneish' );
is( $obj->rand(), .3,           'testing $obj->rand == .3' );
is( $obj->rand(), .2,           'testing $obj->rand == .2' );
is( $obj->rand(), .1,           'testing $obj->rand == .1' );
is( $obj->rand(), 0, 'testing $obj->rand == 0 (nothing left in $obj->srand array' );

