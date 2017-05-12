#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Test::Mock::Test' );
}

diag( "Testing Test::Mock::Test $Test::Mock::Test::VERSION, Perl $], $^X" );
