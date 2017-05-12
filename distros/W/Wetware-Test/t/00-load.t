#!perl

use Test::More tests => 3;

BEGIN {
	use_ok( 'Wetware::Test::Suite' );
	use_ok( 'Wetware::Test::Mock' );
	use_ok( 'Wetware::Test' );
}

diag( "Testing Wetware::Test $Wetware::Test::VERSION, Perl $], $^X" );
