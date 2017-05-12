
use strict;
use Test::More tests => 43;
use XML::TinyXML;
use XML::TinyXML::Selector;
use Data::Dumper;

BEGIN { use_ok('XML::TinyXML::Selector::XPath::Functions') };

my $txml = XML::TinyXML->new();
$txml->loadFile("./t/t.xml");
my $selector = XML::TinyXML::Selector->new($txml, "XPath");

my ($root) = $selector->select("/");
is ($root->name, "xml");

my @set = $selector->select("child::*");
is (scalar(@set), 6);

$selector->resetContext;
my ($node) = $selector->select("child::parent");
is ($root->name, "xml");

$selector->resetContext;
@set = $selector->select("descendant::*");
is (scalar(@set), 11);

($node) = $selector->select("/parent/blah");
is ($node->name, "blah");

@set = map { $_->name } $selector->select("/parent/blah/ancestor::*");
is_deeply (\@set, [ 'parent', 'xml' ]);

$selector->resetContext;
@set = $selector->select("child::parent[child::child1]");
is (scalar(@set), 1);
is ($set[0]->path, "/xml/parent");

$selector->resetContext;
@set = $selector->select("child::parent[child::child1]/preceding-sibling::*");
is (scalar(@set), 3);
is ($set[0]->name, "foo");

$selector->resetContext;
@set = $selector->select("child::parent[child::blah='SECOND']");
is (scalar(@set), 1);
is ($set[0]->getChildNode(0)->name, "blah"); # tests both last selection and getChildNode
@set = $selector->select("attribute::*"); # reusing last context node
is (scalar(@set), 1);
is_deeply ([$set[0]->name, $set[0]->value], ['attr', 'val']); # ensure it's the expected attribute
is ($set[0]->value, 'val'); # retro-compatibility check

$selector->resetContext;
@set = $selector->select("child::parent[child::blah='SECOND']/following-sibling::*");
is (scalar(@set), 1);
is ($set[0]->name, "qtest");

$selector->resetContext;
@set = $selector->select("child::parent[child::blah='NOT EXISTING' or child::child1]/following-sibling::*");
is (scalar(@set), 2);
is_deeply ([ map { $_->name } @set ], [ 'parent', 'qtest' ]);

$selector->resetContext;
@set = $selector->select("child::parent[child::blah='NOT EXISTING' and child::child1]");
is (scalar(@set), 0);

$selector->resetContext;
@set = $selector->select("child::parent[(child::blah='NOT EXISTING' and child::child1) or child::child2]");
is (scalar(@set), 1);
is ($set[0]->name, 'parent');
ok ($set[0]->getChildNodeByName('child2')->name, "child2"); # tests both last selection and getChildNodeByName 

$selector->resetContext;
@set = $selector->select("child::parent[child::blah='SECOND']/attribute::*");
is (scalar(@set), 1);
is ($set[0]->value, 'val');

$selector->resetContext;
@set = $selector->select("child::parent[child::blah='SECOND']/attribute::attr");
is (scalar(@set), 1);
is_deeply ([ $set[0]->name, $set[0]->value ], ['attr', 'val']); # ensure it's the expected attribute (again)

$selector->resetContext;
@set = $selector->select("child::parent[position()=2]");
is (scalar(@set), 1);
is ($set[0]->getChildNode(0)->name, "blah");

$selector->resetContext;
@set = $selector->select("child::parent[position()=last()]");
is (scalar(@set), 1);
is ($set[0]->getChildNode(0)->name, "blah");

$selector->resetContext;
@set = $selector->select("child::parent[position()=last()-1]");
is (scalar(@set), 1);
is ($set[0]->getChildNode(0)->name, "child1");

$selector->resetContext;
@set = $selector->select("child::parent[position()=1+1]");
is (scalar(@set), 1);
is ($set[0]->getChildNode(0)->name, "blah");

# now check if using "2 mod 3" instead of "1+1" produces the same result
$selector->resetContext;
my @set2 = $selector->select("child::parent[position()=2 mod 3]");
is_deeply(\@set, \@set2);

$selector->resetContext;
@set = $selector->select("child::parent[position()>=1][position()=2]");
is (scalar(@set), 1);
is ($set[0]->getChildNode(0)->name, "blah");

$selector->resetContext;
@set = $selector->select("descendant::*[attribute::attr]");
is (scalar(@set), 2);
is_deeply ([ map { $_->name } @set ], [qw(parent blah)]);

$selector->resetContext;
@set = $selector->select("descendant::*[attribute::attr='val2']");
is (scalar(@set), 1);
is_deeply ([ $set[0]->name, $set[0]->value  ], [qw(blah SECOND)]);

