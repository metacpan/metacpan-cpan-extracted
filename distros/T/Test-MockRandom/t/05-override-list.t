# Test::MockRandom
use strict;

use Test::More tests => 9;

#--------------------------------------------------------------------------#
# Test package overriding via import
#--------------------------------------------------------------------------#

use Test::MockRandom qw( SomePackage __PACKAGE__ );
use lib qw( ./t );
use SomePackage;

can_ok( 'SomePackage', 'rand' );
for (qw(srand oneish)) {
    ok(
        !UNIVERSAL::can( 'SomePackage', $_ ),
        "confirming $_ wasn't exported to SomePackage"
    );
}

can_ok( __PACKAGE__, $_ ) for qw( rand srand oneish );

my $obj = SomePackage->new;
isa_ok( $obj, 'SomePackage' );
srand( .5, .6 );
is( $obj->next_random(), .5, 'testing $obj->next_random == .5' );
is( rand,                .6, 'testing rand == .6 in current package' );

