use XML::Tiny qw(parsefile);

use strict;
require "t/test_functions";
print "1..20\n";

$^W = 1;

my @encodings = ( "UTF-8", "UTF-16-BE", "UTF-16-LE", "UTF-32-BE", "UTF-32-LE" );

foreach my $encoding (@encodings) {
  ok(my $xml = parsefile("t/bom-$encoding.xml"), "Don't choke on $encoding BOM in file");
  is($xml->[0]->{attrib}->{bar}, "hlagh", "  parse it correctly");

  open(my $fh, "t/bom-$encoding.xml");
  ok($xml = parsefile("_TINY_XML_STRING_".<$fh>), "Don't choke on $encoding BOM in string");
  is($xml->[0]->{attrib}->{bar}, "hlagh", "  parse it correctly");
}
