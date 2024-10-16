use Test::Builder::Tester tests=>2;
use Test::More;
use Test::XML::Simple;
use XML::LibXML;

my $valid = <<EOS;
<CATALOG>
  <CD>
    <TITLE>Sacred Love</TITLE>
    <ARTIST>Sting</ARTIST>
    <COUNTRY>USA</COUNTRY>
    <COMPANY>A&amp;M</COMPANY>
    <PRICE>12.99</PRICE>

    <YEAR>2003</YEAR>
  </CD>
</CATALOG>
EOS

test_out("ok 1 - good xml");
xml_valid($valid, "good xml");
test_test('good xml');

my $xml_doc = XML::LibXML->createDocument( '1.0' );

test_out('ok 1 - good xml doc object');
xml_valid( $xml_doc, 'good xml doc object' );
test_test('good xml doc object');
