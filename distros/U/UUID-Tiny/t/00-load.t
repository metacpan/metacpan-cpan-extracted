#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'UUID::Tiny' );
}

diag( "Testing UUID::Tiny $UUID::Tiny::VERSION, Perl $], $^X" );
