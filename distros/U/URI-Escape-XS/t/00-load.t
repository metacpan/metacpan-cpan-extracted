#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'URI::Escape::XS' );
}

diag( "Testing URI::Escape::XS $URI::Escape::XS::VERSION, Perl $], $^X" );
