#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Text::vFile::toXML' );
}

diag( "Testing Text::vFile::toXML $Text::vFile::toXML::VERSION, Perl $], $^X" );
