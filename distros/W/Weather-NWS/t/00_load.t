#!perl -T

use Test::More tests => 2;

BEGIN {
	use_ok( 'Weather::NWS::NDFDgen' );
	use_ok( 'Weather::NWS::NDFDgenByDay' );
}

diag( "Testing Weather::NWS::NDFDgen $Weather::NWS::NDFDgen::VERSION, Perl $], $^X" );
