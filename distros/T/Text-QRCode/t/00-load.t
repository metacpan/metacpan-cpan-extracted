#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Text::QRCode' );
}

diag( "Testing Text::QRCode $Text::QRCode::VERSION, Perl $], $^X" );
