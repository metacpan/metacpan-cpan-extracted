use Test::Builder::Tester tests=>2;
use Test::XML::Simple;

my $xml = <<EOS;
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

my $fragment = <<EOS;
<ARTIST>Sting</ARTIST>
EOS

test_out("ok 1 - deep match");
xml_is_deeply($xml, "//ARTIST", $fragment, "deep match");
test_test('deep match');

test_out('ok 1 - identical match');
xml_is_deeply($xml, "/", $xml, "identical match");
test_test('identical match');
