#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Text::EasyTemplate' );
}

diag( "Testing Text::EasyTemplate $Text::EasyTemplate::VERSION, Perl $], $^X" );
