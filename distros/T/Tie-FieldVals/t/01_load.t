use Test::More tests => 5;

BEGIN {
use_ok( 'Tie::FieldVals' );
use_ok( 'Tie::FieldVals::Row' );
use_ok( 'Tie::FieldVals::Select' );
use_ok( 'Tie::FieldVals::Join' );
use_ok( 'Tie::FieldVals::Row::Join' );
}

diag( "Testing Tie::FieldVals ${Tie::FieldVals::VERSION}" );
