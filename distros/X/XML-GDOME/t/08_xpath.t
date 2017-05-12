use Test;
BEGIN { plan tests => 18 }
END { ok(0) unless $loaded }
use XML::GDOME;
$loaded = 1;
ok(1);
use strict;

my $doc = XML::GDOME->createDocFromURI("t/xml/test-xpath.xml", GDOME_LOAD_PARSING);

my $el = $doc->getDocumentElement;
my $attr_val = $el->getAttribute('c');

my $res = $doc->xpath_evaluate("//p");
my $gnode = $res->singleNodeValue;
ok($gnode->tagName, "p");

$gnode = $res->iterateNext;
ok($gnode->tagName, "p");

$gnode = $res->iterateNext;
ok($gnode->tagName, "p");

$gnode = $res->iterateNext;
ok($gnode, undef);

my $nsresolv = $el->xpath_createNSResolver;

$res = $doc->xpath_evaluate("//foo:bar/*", $nsresolv);
ok ($res->resultType, ORDERED_NODE_ITERATOR_TYPE);

$gnode = $res->iterateNext;
ok($gnode->tagName, "foo:a1");

$gnode = $res->iterateNext;
ok($gnode->tagName, "foo:a2");

$res = $doc->xpath_evaluate("count(//p)");
ok ($res->resultType, NUMBER_TYPE);
ok ($res->numberValue, 2);

$res = $doc->xpath_evaluate("concat('abc','def')");
ok ($res->resultType, STRING_TYPE);
ok ($res->stringValue, "abcdef");

$res = $doc->xpath_evaluate("true()");
ok ($res->resultType, BOOLEAN_TYPE);
ok ($res->booleanValue, 1);

$res = $doc->xpath_evaluate("//namespace::*");
$gnode = $res->iterateNext;
$gnode = $res->iterateNext;
ok ($gnode->nodeType, XPATH_NAMESPACE_NODE);
ok ($gnode->prefix, "foo");
ok ($gnode->nodeName, "foo");
ok ($gnode->namespaceURI, "http://foo.com/baz");
$gnode = $res->iterateNext;
