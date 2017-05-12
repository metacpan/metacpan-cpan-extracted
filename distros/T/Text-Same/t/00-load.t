#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Text::Same' );
}

diag( "Testing Text::Same $Text::Same::VERSION, Perl $], $^X" );
