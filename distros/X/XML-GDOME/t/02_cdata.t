use Test;
BEGIN { plan tests => 17 }
END { ok(0) unless $loaded }
use XML::GDOME;
$loaded = 1;
ok(1);
use strict;

my $di = XML::GDOME::DOMImplementation::mkref();

my $doc = $di->createDocument(undef, "TEST", undef);
my $txt = $doc->createTextNode("Initial String");

ok($txt->length, 14);
ok($txt->data, "Initial String");
$txt->setData("0123456789");
ok($txt->data, "0123456789");
ok($txt->substringData(3,3),"345");
ok($txt->substringData(4,10),"456789");
$txt->appendData("ABCDEF");
ok($txt->data,"0123456789ABCDEF");
$txt->insertData(3, "X");
ok($txt->data,"012X3456789ABCDEF");
$txt->deleteData(3,1);
ok($txt->data,"0123456789ABCDEF");
$txt->deleteData(10,8);
ok($txt->data, "0123456789");
$txt->replaceData(0,3,"ABC");
ok($txt->data, "ABC3456789");
$txt->replaceData(4,3,"XXXXXX");
ok($txt->data, "ABC3XXXXXX789");
$txt->replaceData(12,1,"XABCDEF");
ok($txt->data, "ABC3XXXXXX78XABCDEF");
my $txt1 = $txt->splitText(10);
ok($txt->data, "ABC3XXXXXX");
ok($txt1->data, "78XABCDEF");
my $node = $txt->nextSibling;
ok($node->gdome_ref, $txt1->gdome_ref);
$node = $txt1->previousSibling;
ok($node->gdome_ref, $txt->gdome_ref);
