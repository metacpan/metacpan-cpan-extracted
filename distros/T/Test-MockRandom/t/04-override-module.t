# Test::MockRandom
use strict;

use Test::More tests => 8;

#--------------------------------------------------------------------------#
# Test package overriding via import
#--------------------------------------------------------------------------#

use Test::MockRandom qw( SomePackage );
use lib qw( ./t );
use SomePackage;

can_ok( 'SomePackage', 'rand' );
can_ok( __PACKAGE__, $_ ) for qw ( srand oneish );

ok( !UNIVERSAL::can( __PACKAGE__, 'rand' ),
    "confirming that rand() wasn't imported into " . __PACKAGE__ );
ok( !UNIVERSAL::can( 'SomePackage', 'srand' ),
    "confirming that srand wasn't imported into SomePackage" );
ok( !UNIVERSAL::can( 'SomePackage', 'oneish' ),
    "confirming that oneish wasn't imported into SomePackage" );

my $obj = SomePackage->new;
isa_ok( $obj, 'SomePackage' );
srand(.5);
is( $obj->next_random(), .5, 'testing $obj->next_random == .5' );

