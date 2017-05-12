use Test;
BEGIN { plan tests => 28 }
END { ok(0) unless $loaded }
use XML::GDOME;
$loaded = 1;
ok(1);
use strict;

my $doc = XML::GDOME->createDocFromURI("t/xml/test-node.xml", GDOME_LOAD_PARSING);
my $el = $doc->getDocumentElement;

my $nl = $el->childNodes;
my $node1 = $nl->item(1);
my $node2 = $nl->item(3);
my $node3 = $nl->item(5);
my $node4 = $nl->item(7);
my $node5 = $nl->item(9);

my $nnm = $node3->attributes;
ok($nnm->length,2);

ok($el->firstChild->gdome_ref, $nl->item(0)->gdome_ref);
ok($el->lastChild->gdome_ref, $nl->item($nl->length-1)->gdome_ref);

ok($node2->localName,"NODE2");
ok($node3->localName,undef);

ok($node2->namespaceURI,"urn:test.tst");
ok($node3->namespaceURI,undef);

ok($node2->nextSibling->gdome_ref, $nl->item(4)->gdome_ref);

ok($node1->nodeName,"NODE1");
ok($node2->nodeName,"tns:NODE2");
my $tnode = $node1->firstChild;
ok($tnode->nodeName,"#text");

ok($node2->nodeType, ELEMENT_NODE);

$tnode = $node2->firstChild;
ok($tnode->nodeValue, "This is a node with a namespace");

ok($node2->ownerDocument->gdome_ref, $node3->ownerDocument->gdome_ref);

ok($node2->parentNode->gdome_ref, $el->gdome_ref);

ok($node2->prefix,"tns");
ok($node3->prefix,undef);

ok($node2->previousSibling->gdome_ref, $nl->item(2)->gdome_ref);

$tnode->setNodeValue("xxxxx");
ok($tnode->nodeValue,"xxxxx");

$tnode = $nnm->getNamedItem("ATTR1");
$tnode->setNodeValue("Ciao");
ok($tnode->nodeValue,"Ciao");

$node2->setPrefix("xxx");
ok($node2->prefix,"xxx");

ok($node1->hasChildNodes);
ok(!$node4->hasChildNodes);

ok($node3->hasAttributes);
ok(!$node1->hasAttributes);

$el->appendChild($node1);
$node5 = $el->replaceChild($node4,$node5);
$el->insertBefore($node2,$node1);
$el->insertBefore($node3,$node2);
$node4 = $el->removeChild($node4);
$el->insertBefore($node4,$node3);
$el->insertBefore($node5,$node4);

$tnode = $nl->item(0);
my $cnode = $tnode->cloneNode(0);
$el->insertBefore($cnode, $node5);
$cnode = $tnode->cloneNode(0);
$el->insertBefore($cnode, $node4);
$cnode = $tnode->cloneNode(0);
$el->insertBefore($cnode, $node3);
$cnode = $tnode->cloneNode(0);
$el->insertBefore($cnode, $node2);
$cnode = $tnode->cloneNode(0);
$el->insertBefore($cnode, $node1);
$tnode->setNodeValue("\n");
$el->appendChild($tnode);

for my $i (0 .. 4) {
  $tnode = $nl->item(0);
  $el->removeChild($tnode);
}

my $df = $doc->createDocumentFragment;
my $cmt1 = $doc->createComment("*** Start of the new nodes ***");
my $cmt2 = $doc->createComment("*** Stop of the new nodes ***");

my $attr1 = $doc->createAttribute("DTATTR1");
$attr1->setValue("dtattr1");
my $attr2 = $doc->createAttribute("DTATTR2");
$attr2->setValue("dtattr2");

my $txt1 = $doc->createTextNode("\n  ");
my $txt2 = $doc->createTextNode("\n  ");
my $txt3 = $doc->createTextNode("\n  ");
my $txt4 = $doc->createTextNode("\n  ");
my $txt5 = $doc->createTextNode("\n  ");
my $txt6 = $doc->createTextNode("\n    ");

my $el1 = $doc->createElement("DTEL1");
$el1->setAttributeNode($attr1);
my $el2 = $doc->createElement("DTEL2");
$el2->setAttributeNode($attr2);
$el1->appendChild($txt6);
$el1->appendChild($el2);
$el1->appendChild($txt5);
my $el3 = $doc->createElement("DTEL3");

$df->appendChild($cmt1);
$df->appendChild($txt1);
$df->appendChild($el1);
$df->appendChild($txt2);
$df->appendChild($el3);
$df->appendChild($txt3);
$df->appendChild($cmt2);
$df->appendChild($txt4);

$nl = $doc->getElementsByTagName("NODE3");
my $tel = $nl->item(0);
my $root = $tel->parentNode;
ok($root->insertBefore($df, $tel));

my $output = $doc->toString(GDOME_SAVE_STANDARD);
ok($output, qq{<?xml version="1.0"?>
<TEST xmlns:tns="urn:test.tst">
  <NODE5/>
  <NODE4/>
  <!--*** Start of the new nodes ***-->
  <DTEL1 DTATTR1="dtattr1">
    <DTEL2 DTATTR2="dtattr2"/>
  </DTEL1>
  <DTEL3/>
  <!--*** Stop of the new nodes ***-->
  <NODE3 ATTR1="Ciao" tns:ATTR1="Bye">This a attributed node</NODE3>
  <xxx:NODE2>xxxxx</xxx:NODE2>
  <NODE1>This is a test string</NODE1>
</TEST>
});

