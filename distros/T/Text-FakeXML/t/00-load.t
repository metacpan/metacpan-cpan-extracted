#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Text::FakeXML' );
}

diag( "Testing Text::FakeXML $Text::FakeXML::VERSION, Perl $], $^X" );
