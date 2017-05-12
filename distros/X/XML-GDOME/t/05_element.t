use Test;
BEGIN { plan tests => 33 }
END { ok(0) unless $loaded }
use XML::GDOME;
$loaded = 1;
ok(1);
use strict;

my $doc = XML::GDOME->createDocFromURI("t/xml/test-element.xml", GDOME_LOAD_PARSING);
my $el = $doc->documentElement;
undef $doc;
my @nodes = $el->getChildNodes;
for  my $node (@nodes) {
  if ($node->getNodeType == ELEMENT_NODE) {
    my $nnm = $node->attributes;
  }
}
ok($el->tagName,"TEST");

my $nnm = $el->attributes;
ok(defined($nnm));

my $attr = $el->getAttributeNode("XXXX");
ok($attr,undef);

$attr = $el->getAttributeNode("FOO1");
ok($attr->nodeName,"FOO1");

my $attrNS = $el->getAttributeNodeNS("urn:xxxx.xxxx.xx","CIPPO2");
ok($attrNS,undef);
$attrNS = $el->getAttributeNodeNS("urn:cips.ciak.uk","XXXXX");
ok($attrNS,undef);
$attrNS = $el->getAttributeNodeNS("urn:cips.ciak.uk","CIPPO2");
ok($attrNS->nodeName,"pippo:CIPPO2");

$attr = $el->removeAttributeNode($attr);
ok($attr->nodeName,"FOO1");

$attrNS = $el->removeAttributeNode($attrNS);
ok($attrNS->nodeName,"pippo:CIPPO2");
ok($el->getAttributeNodeNS("urn:cips.ciak.uk","CIPPO2"), undef);

my $attrDef = $el->getAttributeNode("FOO2");
$attrDef = $el->removeAttributeNode($attrDef);
ok($attrDef->nodeName,"FOO2");
ok($attrDef->nodeValue,"bar2");

my $attr_temp = $el->setAttributeNode($attr);
ok($attr_temp,undef);
ok($el->getAttributeNode("FOO1"));
ok($attr->nodeName,"FOO1");

$attr_temp = $el->setAttributeNodeNS($attrNS);
ok($attr_temp,undef);
ok($el->getAttributeNodeNS("urn:cips.ciak.uk","CIPPO2"));
ok($attrNS->nodeName,"pippo:CIPPO2");

my $temp_str = $el->getAttribute("FOO3");
ok($temp_str, "bar3");

$temp_str = $el->getAttribute("");
ok($temp_str, "");

$temp_str = $el->getAttributeNS("urn:cips.ciak.uk","CIPPO3");
ok($temp_str,"lippo3");

$temp_str = $el->getAttributeNS("urn:cips.ciak.uk","XXXXX");
ok($temp_str,"");

$temp_str = $el->getAttributeNS("urn:xxxx.xxxx.xx","CIPPO3");
ok($temp_str,"");

$el->setAttribute("NEWATTR","newvalue");
$temp_str = $el->getAttribute("NEWATTR");
ok($temp_str, "newvalue");

$el->setAttributeNS("urn:myns.casarini.org","myns:NEWATTR1","newvalue1");
$temp_str = $el->getAttributeNS("urn:myns.casarini.org","NEWATTR1");
ok($temp_str, "newvalue1");

$el->removeAttribute("FOO4");
$temp_str = $el->getAttribute("FOO4");
ok($temp_str, "");

$el->removeAttributeNS("urn:cips.ciak.uk","CIPPO4");
$temp_str = $el->getAttributeNS("urn:cips.ciak.uk","CIPPO4");
ok($temp_str, "");

ok($el->hasAttribute("NEWATTR"));
ok(!$el->hasAttribute("BOBOBO"));
ok($el->hasAttributeNS("urn:myns.casarini.org","NEWATTR1"));
ok(!$el->hasAttributeNS("urn:myns.casarini.org","BOBOBOB"));
ok(!$el->hasAttributeNS("urn:myns.xxxx.xx","NEWATTR1"));
