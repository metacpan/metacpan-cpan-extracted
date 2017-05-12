# vim:set ft=perl:
use lib 'lib';

use Test::More 'no_plan';
use XML::DOM::Lite qw(Parser :constants);

my $xmlstr = q{
<page foo="bar">
  <para id="thing1">para thing</para>
  <para id="thing2">para thing</para>
  <para id="thing3">para thing</para>
  <para id="thing4">para thing</para>
</page>
};
my $parser = Parser->new(whitespace => 'strip');
ok($parser);

my $doc = $parser->parse($xmlstr);
ok($doc);

my $page = $doc->documentElement;
ok($page);

is($doc->getElementById("thing2"), $page->firstChild->nextSibling);
my $node = $doc->selectSingleNode(q{/page[@foo='bar']});
is($node, $page);

my $frag = $doc->createDocumentFragment;
ok($frag->nodeType == DOCUMENT_FRAGMENT_NODE);
my $new1 = $doc->createElement('fragchild1');
my $new2 = $doc->createElement('fragchild2');
my $new3 = $doc->createElement('fragchild3');
$frag->appendChild($new1);
$frag->appendChild($new2);
$frag->appendChild($new3);

is($frag->childNodes->length, 3);
$page->appendChild($frag);
is($frag->childNodes->length, 0);
is($page->lastChild, $new3);
