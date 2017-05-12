# Test::MockRandom
use strict;

use Test::More tests => 6;

#--------------------------------------------------------------------------#
# Test package overriding via import
#--------------------------------------------------------------------------#

use Test::MockRandom __PACKAGE__;
use lib qw( . ./t );
use SomeRandPackage;

# SomeRandPackage has its own rand(), so we have to re-override
BEGIN { Test::MockRandom->export_rand_to('SomeRandPackage') }

for (qw ( rand srand oneish )) {
    can_ok( __PACKAGE__, $_ );
}

my $obj = SomeRandPackage->new;
isa_ok( $obj, 'SomeRandPackage' );
can_ok( $obj, qw ( rand ) );
srand(.5);
is( $obj->rand(), .5, 'testing $obj->rand == .5' );

