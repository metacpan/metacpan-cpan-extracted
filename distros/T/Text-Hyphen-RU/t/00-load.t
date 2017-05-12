#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Text::Hyphen' );
}

diag( "Testing Text::Hyphen $Text::Hyphen::VERSION, Perl $], $^X" );
