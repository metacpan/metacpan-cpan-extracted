# vim:set ft=perl:
use lib 'lib';

use Test::More 'no_plan';
use XML::DOM::Lite qw(Parser :constants);

my $xmlstr = q{
<page foo="bar">
  <para title="thing1">para thing</para>
  <para title="thing2">para thing</para>
  <para title="thing3">para thing</para>
  <para title="thing4">para thing</para>
</page>
};
my $parser = Parser->new(whitespace => 'strip');
ok($parser);

my $doc = $parser->parse($xmlstr);
ok($doc);

my $page = $doc->documentElement;
ok($page);

my $para = $page->firstChild;
ok($para);
is($para->parentNode, $page);
is($page->firstChild, $para);
is($para->nextSibling, $page->childNodes->[1]);
is($para->nextSibling->previousSibling, $para);
is($para->nodeType, ELEMENT_NODE);

my $next = $para->nextSibling;
ok($next);
is($page->removeChild($para), $para);
is($para->parentNode, undef);

is($page->childNodes->length, 3);
is($page->firstChild, $next);
is($page->firstChild->previousSibling, undef);

my $last = $page->lastChild;
$page->insertBefore($para, $page->lastChild);
is($page->lastChild, $last);
is($page->lastChild->previousSibling, $para);

