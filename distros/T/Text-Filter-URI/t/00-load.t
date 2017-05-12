#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Text::Filter::URI' );
}

diag( "Testing Text::Filter::URI $Text::Filter::URI::VERSION, Perl $], $^X" );
