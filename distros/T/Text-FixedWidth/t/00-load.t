#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Text::FixedWidth' );
}

diag( "Testing Text::FixedWidth $Text::FixedWidth::VERSION, Perl $], $^X" );
