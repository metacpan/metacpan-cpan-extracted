#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Tie::Hash::Method' );
}

diag( "Testing Tie::Hash::Method $Tie::Hash::Method::VERSION, Perl $], $^X" );
