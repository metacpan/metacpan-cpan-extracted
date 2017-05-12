# Test::MockRandom
use strict;

use Test::More;

plan tests => 8;

#--------------------------------------------------------------------------#
# Test rand(@list) uses scalar context (in RandomList.pm)
#--------------------------------------------------------------------------#

use Test::MockRandom qw( CORE::GLOBAL );
use lib qw( ./t );
use RandomList;

for ( __PACKAGE__, "RandomList" ) {
    is( UNIVERSAL::can( $_, 'rand' ),
        undef, "rand should not have been imported into $_" );
}
for (qw ( srand oneish )) {
    can_ok( __PACKAGE__, $_ );
}

my $list = RandomList->new( 0, 1, 2, 3, 4, 5 );
isa_ok( $list, 'RandomList' );

srand(0);
is( $list->random(), 0, 'testing $list->random() -- return first element' );

srand( oneish() );
is( $list->random(), 5, 'testing $list->random() -- return last element' );

srand(.49);
is( $list->random(), 2, 'testing $list->random() -- return third element' );

