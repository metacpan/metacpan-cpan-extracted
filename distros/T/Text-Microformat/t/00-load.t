#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Text::Microformat' );
}

diag( "Testing Text::Microformat $Text::Microformat::VERSION, Perl $], $^X" );
