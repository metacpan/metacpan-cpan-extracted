#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Text::Lorem::More' );
}

diag( "Testing Text::Lorem::More $Text::Lorem::More::VERSION, Perl $], $^X" );
