#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Text::Pretty' );
}

diag( "Testing Text::Pretty $Text::Pretty::VERSION, Perl $], $^X" );
