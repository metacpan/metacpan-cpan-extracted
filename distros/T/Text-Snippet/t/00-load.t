#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Text::Snippet' );
}

diag( "Testing Text::Snippet $Text::Snippet::VERSION, Perl $], $^X" );
