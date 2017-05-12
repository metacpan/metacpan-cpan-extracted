#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Text::SpellChecker::GUI' );
}

diag( "Testing Text::SpellChecker::GUI $Text::SpellChecker::GUI::VERSION, Perl $], $^X" );
