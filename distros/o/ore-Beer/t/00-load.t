#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'ore::Beer' );
}

diag( "Testing ore::Beer $ore::Beer::VERSION, Perl $], $^X" );
