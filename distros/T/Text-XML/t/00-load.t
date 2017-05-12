#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Text::XML' );
}

diag( "Testing Text::XML $Text::XML::VERSION, Perl $], $^X" );
