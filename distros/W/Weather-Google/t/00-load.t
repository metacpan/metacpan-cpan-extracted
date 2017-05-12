#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Weather::Google' );
}

diag( "Testing Weather::Google $Weather::Google::VERSION, Perl $], $^X" );
