# Module load test
use Test::More tests => 1;

BEGIN {
	use_ok( 'WebService::Zusaar' );
}

diag( "Testing WebService::Zusaar $WebService::Zusaar::VERSION" );

