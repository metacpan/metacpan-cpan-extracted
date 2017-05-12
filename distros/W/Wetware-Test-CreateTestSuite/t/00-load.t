#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Wetware::Test::CreateTestSuite' );
}

diag( "Testing Wetware::Test::CreateTestSuite $Wetware::Test::CreateTestSuite::VERSION, Perl $], $^X" );
