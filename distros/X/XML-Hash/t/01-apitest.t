use Test::More tests => 4;
use Test::XML;
use strict;
use warnings; 

use XML::Hash;
use XML::DOM;
use Data::Dumper;
use Scalar::Util qw/refaddr/;

my $xml_converter = XML::Hash->new();

my $xml = <<__XML;
<hosts>
    <server os="linux" type="redhat" version="8.0">
      <address>192.168.0.1</address>
      <address>192.168.0.2</address>
    </server>
    <server os="linux" type="suse" version="7.0">
      <address>192.168.1.10</address>
      <address>192.168.1.20</address>
    </server>
    <server address="192.168.2.100" os="linux" type="conectiva" version="9.0"/>
    <server address="192.168.3.30" os="bsd" type="freebsd" version="9.0"/>
</hosts>
__XML

my $xml_doc = XML::DOM::Parser->new()->parse($xml);

# Test 1: Convertion from a XML String to a Hash
my $xml_hash = $xml_converter->fromXMLStringtoHash($xml);
isa_ok( $xml_hash, "HASH", "fromXMLStringtoHash: Convertion from a XML String to a Hash" );

# Test 2: Convertion from a Hash back into a XML String
my $xml_str = $xml_converter->fromHashtoXMLString($xml_hash);
# diag("Got a ref: " .Dumper($xml_str));
is_xml( $xml_str, $xml, "fromHashtoXMLString: Convertion from a Hash back into a XML String" );

# Test 3: Convertion from a XML::DOM::Document into a HASH
$xml_hash = $xml_converter->fromDOMtoHash($xml_doc);
#diag("Got a ref: " .Dumper($xml_hash));
isnt( $xml_hash, undef,"fromDOMtoHash: Convertion from a XML::DOM::Document into a HASH");

# Test 4: Convertion from a HASH back info a XML::DOM::Document
$xml_doc = $xml_converter->fromHashtoDOM($xml_hash);
#diag("Got a ref: " . $xml_doc->toString());
isa_ok( $xml_doc, "XML::DOM::Document", "fromHashtoDOM: Convertion from a HASH back into a XML::DOM::Document");

# Test 5: Convertion from a File into a HASH
#$xml_hash = $xml_converter->fromXMLFiletoHash("book.xml");
#diag("Got a ref: " .Dumper($xml_hash));
#isnt( $xml_hash, undef,"fromXMLFiletoHash: Convertion from a File into a HASH");

# Test 6: Convertion from a Hash back into a file
#my $xml_doc = $xml_converter->fromHashtoXMLFile("book_test.xml);
#diag("Got a ref: " . $xml_doc->toString());
#isa_ok( $xml_doc, "XML::DOM::Document", "fromHashtoXMLFile: Convertion from a Hash back into a file");



