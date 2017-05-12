#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'URI::crid' );
}

diag( "Testing URI::crid $URI::crid::VERSION, Perl $], $^X" );
