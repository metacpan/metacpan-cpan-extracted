#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Tie::Expression' );
}

diag( "Testing Tie::Expression $Tie::Expression::VERSION, Perl $], $^X" );
