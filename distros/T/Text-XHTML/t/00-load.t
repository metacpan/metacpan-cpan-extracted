#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Text::XHTML' );
}

diag( "Testing Text::XHTML $Text::XHTML::VERSION, Perl $], $^X" );
