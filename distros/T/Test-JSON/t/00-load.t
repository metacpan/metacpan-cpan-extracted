#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Test::JSON' );
}

diag( "Testing Test::JSON $Test::JSON::VERSION, Perl $], $^X" );
