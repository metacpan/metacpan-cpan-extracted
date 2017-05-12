# vim:set ft=perl:
use lib 'lib';

use Test::More tests => 26;

use XML::DOM::Lite qw(Parser Serializer :constants);

my $xmlstr = <<XML;
<?xml version="1.0"?>
<!-- this is a comment -->
<root>
  <item1 attr1="/val1" attr2="val2">text</item1>
  <item2 id="item2id">
    <item3 instance="0"/>
    <item4>
      deep text 1
      <item5>before</item5>
      deep text 2
      <item6>after</item6>
      deep text 3
    </item4>
    <item3 instance="1"/>
  </item2>
  some more text
</root>
XML

my $parser = Parser->new(whitespace => 'strip');
ok($parser);

my $doc = $parser->parse($xmlstr);
ok($doc);

ok($doc->nodeType & DOCUMENT_NODE);
ok($doc->documentElement);
ok($doc->documentElement->tagName eq "root");
ok($doc->documentElement->nodeType & ELEMENT_NODE);

my $item3s = $doc->getElementsByTagName('item3');
ok($item3s);

ok($item3s->isa('XML::DOM::Lite::NodeList'));
ok(scalar(@$item3s) eq 2);
ok(my $item2 = $doc->getElementById("item2id"));
ok($item2->getAttribute("id") eq "item2id");
ok($item2->tagName eq "item2");
ok(ref($item2->parentNode));
ok($doc->documentElement->firstChild->tagName eq "item1", "first child is item1");
ok($doc->documentElement->lastChild->nodeType & TEXT_NODE, "last child is a text node");
ok($doc->documentElement->lastChild->nodeValue eq "some more text", "text is sane at the end");

$xmlstr = <<XML;
<attrTest attr1 = 'attr1: single quotes'
                attr2= "attr2: double quotes"
                attr3 ="attr3: single quote ' in double quotes"
                attr4='attr4: double quote " in single quotes'
                attr5="attr5: lt > in value"/>
XML

$parser = Parser->new(whitespace => 'normalize');
ok($parser);

$doc = $parser->parse($xmlstr);
ok($doc);

ok($doc->documentElement->tagName eq 'attrTest');
ok($doc->documentElement->nodeName eq $doc->documentElement->tagName);

my $docel = $doc->documentElement;
ok($docel);

ok($docel->getAttribute('attr1') eq 'attr1: single quotes');
ok($docel->getAttribute('attr2') eq "attr2: double quotes");
ok($docel->getAttribute('attr3') eq "attr3: single quote ' in double quotes");
ok($docel->getAttribute('attr4') eq 'attr4: double quote " in single quotes');
ok($docel->getAttribute('attr5') eq "attr5: lt > in value");
