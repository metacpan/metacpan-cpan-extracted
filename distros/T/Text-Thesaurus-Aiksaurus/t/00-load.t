#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Text::Thesaurus::Aiksaurus' );
}

diag( "Testing Text::Thesaurus::Aiksaurus $Text::Thesaurus::Aiksaurus::VERSION, Perl $], $^X" );
