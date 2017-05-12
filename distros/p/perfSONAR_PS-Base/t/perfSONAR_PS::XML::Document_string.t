use Test::More 'no_plan';
use Data::Compare qw( Compare );
use XML::LibXML;
use Log::Log4perl qw(get_logger :levels);

#Log::Log4perl->init("../../../services/Daemon/logger.conf");

use_ok('perfSONAR_PS::XML::Document_string');
use perfSONAR_PS::XML::Document_string;

my $n;

# Check the constructor
my $doc0 = perfSONAR_PS::XML::Document_string->new();

ok(defined $doc0, "perfSONAR_PS::XML::Document_string::new");

# Check startElement and endElement
my $doc1 = perfSONAR_PS::XML::Document_string->new();
$n = $doc1->startElement(prefix => "test", tag => "tag1",
	namespace => "http://test/",
	extra_namespaces => {
		test1 => "http://test1/",
		test2 => "http://test2/"
	},
	content => "test1",
	attributes => {
		attr1 => "value",
		attr2 => "value"
	}
	);

ok($n == 0, "perfSONAR_PS::XML::Document_string::startElement - Basic Element");
$n = $doc1->endElement("tag1");
ok($n == 0, "perfSONAR_PS::XML::Document_string::endElement - Basic Element");

my $parser = XML::LibXML->new();
my $dom1;
eval {
    $dom1 = $parser->parse_string($doc1->getValue());
};
ok (!$@, "perfSONAR_PS::XML::Document_string::start/endElement - Parse");
# Check the basic element properties
ok ($dom1->documentElement->prefix eq "test", "perfSONAR_PS::XML::Document_string::start/endElement - Proper Prefix");
ok ($dom1->documentElement->namespaceURI eq "http://test/", "perfSONAR_PS::XML::Document_string::start/endElement - Proper URI");
ok ($dom1->documentElement->nodeName eq "test:tag1", "perfSONAR_PS::XML::Document_string::start/endElement - Proper Tag");
# Check the created namespaces
is ($dom1->documentElement->lookupNamespaceURI("test1"), "http://test1/");
is ($dom1->documentElement->lookupNamespaceURI("test2"), "http://test2/");
is ($dom1->documentElement->lookupNamespacePrefix("http://test1/"), "test1");
is ($dom1->documentElement->lookupNamespacePrefix("http://test2/"), "test2");

# Try ending an element that doesn't exist
$n = $doc1->endElement("tag1");
ok($n != 0, "perfSONAR_PS::XML::Document_string::endElement - End non-existent element");

# Try ending an element that doesn't exist
my $doc2 = perfSONAR_PS::XML::Document_string->new();
$n = $doc2->startElement(prefix => "test", tag => "tag2", namespace => "http://test/");
$n = $doc2->endElement("tag1");
ok($n != 0, "perfSONAR_PS::XML::Document_string::endElement - End incorrect element");
$n = $doc2->endElement("tag2");

# Check createElement
my $doc3 = perfSONAR_PS::XML::Document_string->new();
$n = $doc3->createElement(prefix => "test", tag => "tag1", namespace => "http://test/");
ok($n == 0, "perfSONAR_PS::XML::Document_string::createElement - Basic Element");
my $dom2;
eval {
    $dom2 = $parser->parse_string($doc3->getValue());
};
ok (!$@, "perfSONAR_PS::XML::Document_string::createElement - Parse");
ok ($dom2->documentElement->prefix eq "test", "perfSONAR_PS::XML::Document_string::createElement - Proper Prefix");
ok ($dom2->documentElement->namespaceURI eq "http://test/", "perfSONAR_PS::XML::Document_string::createElement - Proper URI");
ok ($dom2->documentElement->nodeName eq "test:tag1", "perfSONAR_PS::XML::Document_string::createElement - Proper Tag");

# Check addOpaque
my $doc4 = perfSONAR_PS::XML::Document_string->new();
my $data = "junk to add and test";
$n = $doc4->addOpaque($data);
ok ($n == 0);
is ($doc4->getValue(), $data);
