#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Test::TAP' );
}

diag( "Testing Test::TAP $Test::TAP::VERSION, Perl $], $^X" );
