use Test::More tests => 1;

BEGIN {
use_ok( 'UNIVERSAL::cant' );
}

diag( "Testing UNIVERSAL::cant $UNIVERSAL::cant::VERSION" );
