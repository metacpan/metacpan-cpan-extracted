use Test::Builder::Tester tests => 4;
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

test_out('ok 1 - good node');
xml_node($xml, "//ARTIST", "good node");
test_test('xml_node, good node');

test_out("not ok 1 - Couldn't find /CATALOG/ARTIST");
test_fail(+1);
xml_node($xml, "/CATALOG/ARTIST", "bad path");
test_test('xml_node, bad path');

test_out('ok 1 - full path');
xml_node($xml, "/CATALOG/CD/ARTIST", "full path");
test_test('xml_node, full path');

test_out("not ok 1 - Couldn't find //FORMAT");
test_fail(+1);
xml_node($xml, "//FORMAT", "bad node");
test_test('xml_node, bad node');
