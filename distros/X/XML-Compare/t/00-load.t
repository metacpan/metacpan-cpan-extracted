#!perl -T

use Test::More tests => 4;

BEGIN {
	use_ok( 'XML::Compare' );
}

can_ok('XML::Compare', 'same');
can_ok('XML::Compare', 'is_same');
can_ok('XML::Compare', 'is_different');

diag( "Testing XML::Compare $XML::Compare::VERSION, Perl $], $^X, XML::LibXML $XML::LibXML::VERSION" );
