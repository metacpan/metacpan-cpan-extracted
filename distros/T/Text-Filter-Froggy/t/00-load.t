#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Text::Filter::Froggy' );
}

diag( "Testing Text::Filter::Froggy $Text::Filter::Froggy::VERSION, Perl $], $^X" );
