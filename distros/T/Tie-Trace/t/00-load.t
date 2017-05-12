#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Tie::Trace' );
}

diag( "Testing Tie::Trace $Tie::Trace::VERSION, Perl $], $^X" );
