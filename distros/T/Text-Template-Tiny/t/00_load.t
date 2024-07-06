#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Text::Template::Tiny' );
}

diag( "Testing Text::Template::Tiny $Text::Template::Tiny::VERSION, Perl $], $^X" );
