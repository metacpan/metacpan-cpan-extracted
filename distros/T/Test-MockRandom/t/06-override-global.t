# Test::MockRandom
use strict;

use Test::More tests => 6;

#--------------------------------------------------------------------------#
# Test package overriding via import to global
#--------------------------------------------------------------------------#

use Test::MockRandom qw( CORE::GLOBAL );
use lib qw( . ./t );
use SomePackage;

for ( __PACKAGE__, "SomePackage" ) {
    is( UNIVERSAL::can( $_, 'rand' ),
        undef, "rand should not have been imported into $_" );
}
for (qw ( srand oneish )) {
    can_ok( __PACKAGE__, $_ );
}

my $obj = SomePackage->new;
isa_ok( $obj, 'SomePackage' );
srand(.5);
is( $obj->next_random(), .5, 'testing $obj->next_random == .5' );

