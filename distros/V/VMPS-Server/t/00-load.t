#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'VMPS::Server' );
}

diag( "Testing VMPS::Server $VMPS::Server::VERSION, Perl $], $^X" );
