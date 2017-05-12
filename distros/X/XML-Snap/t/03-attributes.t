#!perl -T

use Test::More tests => 22;

use XML::Snap;
use Data::Dumper;

$xml = XML::Snap->parse ('<test a="aaa" b="bbb" c="ccc"/>');

is ($xml->get('a'), 'aaa');
is ($xml->get('c'), 'ccc');
is ($xml->get('c', 'cccccc'), 'ccc');
is ($xml->get('d'), undef);
is ($xml->get('d', 'ddd'), 'ddd');

@attributes = $xml->attrs;
is_deeply (\@attributes, ['a', 'b', 'c']);

$xml->unset('c');
is ($xml->get('c'), undef);

@attributes = $xml->attrs;
is_deeply (\@attributes, ['a', 'b']);

is ($xml->set('a'), 'aaa');
is ($xml->set('a', 'new value'), 'new value');
is ($xml->get('a'), 'new value');

$xml->set ('e', 'eee');
is ($xml->get ('e'), 'eee');
is ($xml->get ('e', '234'), 'eee');

@attributes = $xml->attrs;
is_deeply (\@attributes, ['a', 'b', 'e']);
$xml->attr_order('b', 'a');
@attributes = $xml->attrs;
#diag Dumper(\@attributes);
is_deeply (\@attributes, ['b', 'a', 'e']);

ok (not $xml->attr_eq('d', 'eee'));
ok ($xml->attr_eq('e', 'eee'));

@values = $xml->getlist ('e', 'a', 'b');
is_deeply (\@values, ['eee', 'new value', 'bbb']);


$xml = XML::Snap->parse ('<test a="aaa" a2="0"><this b="bbb" b2="1"><this3 c="ccc" c2="0"/></this></test>');
$this3 = $xml->first ('this3');
is ($this3->getctx('c', 'xxx'), 'ccc');
is ($this3->getctx('b', 'xxx'), 'bbb');
is ($this3->getctx('a', 'xxx'), 'aaa');
is ($this3->getctx('d', 'xxx'), 'xxx');

