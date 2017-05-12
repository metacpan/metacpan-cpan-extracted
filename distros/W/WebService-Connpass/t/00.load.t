# Module load test
use Test::More tests => 1;

BEGIN {
	use_ok( 'WebService::Connpass' );
}

diag( "Testing WebService::Connpass $WebService::Connpass::VERSION" );

