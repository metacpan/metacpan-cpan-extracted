#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Test::Ping' );
}

diag( "Testing Test::Ping $Test::Ping::VERSION, Perl $], $^X" );
