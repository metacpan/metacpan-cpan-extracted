#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Text::LineNumber' );
}

diag( "Testing Text::LineNumber $Text::LineNumber::VERSION, Perl $], $^X" );
