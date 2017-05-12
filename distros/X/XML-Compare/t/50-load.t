#!perl -T

use Test::More tests => 3;

BEGIN {
    use_ok( 'Test::XML::Compare');
}

can_ok('Test::XML::Compare', 'is_xml_same');
can_ok('Test::XML::Compare', 'is_xml_different');

diag( "Testing Test::XML::Compare $Test::XML::Compare::VERSION, Perl $], $^X, XML::LibXML $XML::LibXML::VERSION" );
