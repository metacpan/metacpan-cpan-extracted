#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Text::SimpleVcard' );
}

diag( "Testing Text::SimpleVcard $Text::SimpleVcard::VERSION, Perl $], $^X" );
