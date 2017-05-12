#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Util::Any' );
}

diag( "Testing Util::Any $Util::Any::VERSION, Perl $], $^X" );
