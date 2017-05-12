#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Test::Server' );
}

diag( "Testing Test::Server $Test::Server::VERSION, Perl $], $^X" );
