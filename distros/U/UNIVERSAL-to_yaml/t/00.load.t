use Test::More tests => 1;

BEGIN {
use_ok( 'UNIVERSAL::to_yaml' );
}

diag( "Testing UNIVERSAL::to_yaml $UNIVERSAL::to_yaml::VERSION" );
