use Test;
BEGIN { plan tests => 48 }
END { ok(0) unless $loaded }
use XML::GDOME;
$loaded = 1;
ok(1);
use strict;
my $doc = XML::GDOME->createDocument(undef, "TEST", undef);
my $root = $doc->documentElement;
ok($root->tagName, "TEST");
my $el1 = $doc->createElement("EL1");
my $tdoc = $el1->ownerDocument;
ok($tdoc->gdome_ref, $doc->gdome_ref);
ok($el1->tagName, "EL1");
my $el2 = $doc->createElementNS("urn:test.tst","tns:EL2");
$tdoc = $el2->ownerDocument;
ok($tdoc->gdome_ref, $doc->gdome_ref);
undef $tdoc;
ok($el2->tagName,"tns:EL2");
ok($el2->localName,"EL2");
ok($el2->namespaceURI,"urn:test.tst");
my $df = $doc->createDocumentFragment;
$tdoc = $el2->ownerDocument;
ok($tdoc->gdome_ref, $doc->gdome_ref);
undef $tdoc;
ok($df->nodeName,"#document-fragment");
undef $df;

my $txt = $doc->createTextNode("<Test>Text Test</Test>");
$tdoc = $txt->ownerDocument;
ok($tdoc->gdome_ref, $doc->gdome_ref);
undef $tdoc;
ok($txt->nodeName,"#text");
ok($txt->nodeValue,"<Test>Text Test</Test>");

my $cds = $doc->createCDATASection("<Test>Text Test</Test>");
$tdoc = $cds->ownerDocument;
ok($tdoc->gdome_ref, $doc->gdome_ref);
undef $tdoc;
ok($cds->nodeName,"#cdata-section");
ok($cds->nodeValue,"<Test>Text Test</Test>");

my $cmt = $doc->createComment("dududu dadada");
$tdoc = $cmt->ownerDocument;
ok($tdoc->gdome_ref, $doc->gdome_ref);
undef $tdoc;
ok($cmt->nodeName,"#comment");
ok($cmt->nodeValue,"dududu dadada");

my $pi = $doc->createProcessingInstruction("sqlprocessor","SELECT * FROM blah");
$tdoc = $pi->ownerDocument;
ok($tdoc->gdome_ref, $doc->gdome_ref);
undef $tdoc;
ok($pi->nodeName,"sqlprocessor");
ok($pi->nodeValue,"SELECT * FROM blah");

my $attr1 = $doc->createAttribute("ATTR1");
$tdoc = $attr1->ownerDocument;
ok($tdoc->gdome_ref, $doc->gdome_ref);
undef $tdoc;
ok($attr1->name,"ATTR1");
ok($attr1->value,"");

my $attr2 = $doc->createAttributeNS("urn:test.tst","tns:ATTR2");
$tdoc = $attr2->ownerDocument;
ok($tdoc->gdome_ref, $doc->gdome_ref);
undef $tdoc;
ok($attr2->name,"tns:ATTR2");
ok($attr2->localName,"ATTR2");
ok($attr2->namespaceURI,"urn:test.tst");
ok($attr2->value,"");

$root->setAttributeNode($attr1);
$el1->setAttributeNode($attr2);
$root->appendChild($el1);
$root->appendChild($pi);
$el2->appendChild($txt);
$el2->appendChild($cds);
$el2->appendChild($cmt);
$root->appendChild($el2);

open E, "t/xml/test-document1.xml";
local($/) = undef;
my $expected = <E>;
close E;
ok($doc->toString, $expected);

$doc = XML::GDOME->createDocFromURI("t/xml/test-document2.xml", GDOME_LOAD_PARSING);

my @els;
for my $i (0 .. 8) {
  # very strange core dump if we remove quotes
  $els[$i] = $doc->getElementById("$i");
}

my $nl = $doc->getElementsByTagName("NODE");
ok($nl->length,9);

for my $i (0 .. 8) {
  my $tel = $nl->item($i);
  ok($els[$i]->gdome_ref,$tel->gdome_ref);
}

$root = $doc->documentElement;
my $tel = $root->removeChild($els[3]);
$tel = $nl->item(3);
ok($tel->gdome_ref, $els[6]->gdome_ref);

$doc = XML::GDOME->createDocFromURI("t/xml/test-document3.xml", GDOME_LOAD_PARSING);

for my $i (0..3) {
  $els[$i] = $doc->getElementById(2 * $i + 1);
}

$nl = $doc->getElementsByTagNameNS("urn:test.tst", "NODE");
ok($nl->length,4);

for my $i (0..3) {
  my $tel = $nl->item($i);
  ok($tel->gdome_ref, $els[$i]->gdome_ref);
}

$root = $doc->documentElement;
$tel = $root->removeChild($els[1]);
$tel = $nl->item(1);
ok($tel->gdome_ref, $els[3]->gdome_ref);
