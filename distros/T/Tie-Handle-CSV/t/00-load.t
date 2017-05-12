#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Tie::Handle::CSV' );
}

diag( "Testing Tie::Handle::CSV $Tie::Handle::CSV::VERSION, Perl $], $^X" );
