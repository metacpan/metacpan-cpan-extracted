#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Text::GooglewikiFormat' );
}

diag( "Testing Text::GooglewikiFormat $Text::GooglewikiFormat::VERSION, Perl $], $^X" );
