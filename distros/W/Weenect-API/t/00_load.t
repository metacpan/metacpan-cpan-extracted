#!perl

use Test::More tests => 9;

BEGIN {
	use_ok( 'Weenect' );
	use_ok( 'Weenect::API' );
	use_ok( 'Weenect::Animal' );
	use_ok( 'Weenect::Connect' );
	use_ok( 'Weenect::Position' );
	use_ok( 'Weenect::Preferences' );
	use_ok( 'Weenect::Tracker' );
	use_ok( 'Weenect::WiFiZone' );
	use_ok( 'Weenect::Zone' );
}

diag( "Testing Weenect API $Weenect::VERSION, Perl $], $^X" );
