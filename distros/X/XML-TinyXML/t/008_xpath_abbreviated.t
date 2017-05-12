
use strict;
use Test::More tests => 31;
use XML::TinyXML;
BEGIN { use_ok('XML::TinyXML::Selector') };

my $txml = XML::TinyXML->new();
$txml->loadFile("./t/t.xml");

# default is allowMultipleRootNodes == 0
my $rnode = $txml->getNode("/");
is ($rnode->name, "xml");
my $node = $rnode->getChildNodeByName("parent[2]"); # this tests predicates support within C library
is ($node->name, "parent");
$node = $txml->getNode("/parent[2]/blah"); # this tests predicates support within C library
is ($node->value, "SECOND");

$txml->allowMultipleRootNodes(1);
# the following 3 tests should really be invalid ... 
# but in multiple-root-nodes we allow to include 
# the rootnodes in the path when using the generic 
# getNode() method
$rnode = $txml->getNode("/xml");
is ($rnode->name, "xml");
$node = $rnode->getChildNodeByName("parent[2]"); # this tests predicates support within C library
is ($node->name, "parent");
$node = $txml->getNode("/xml/parent[2]/blah"); # this tests predicates support within C library
is ($node->value, "SECOND");

my $selector = XML::TinyXML::Selector->new($txml, "XPath");
my @res = $selector->select('//parent');
is (scalar(@res), 2);
@res = $selector->select('/xml//parent'); # XXX INVALID xpath expression
is (scalar(@res), 0);
@res = $selector->select('//parent[1]');
is (scalar(@res), 1);
@res = $selector->select('//parent[2]');
is (scalar(@res), 1);
@res = $selector->select('//child*'); # XXX INVALID xpath expression
is (scalar(@res), 0);

@res = $selector->select('/xml/parent[2]/blah/..'); # XXX INVALID xpath expression
is (scalar(@res), 0);
@res = $selector->select('//blah/..');
is ($res[0]->name, "parent");
@res = $selector->select('//parent[1]/..');
is ($res[0]->name, "xml");
@res = $selector->select('//parent[1]/.');
is ($res[0]->name, "parent");
@res = $selector->select('//blah/.');
is ($res[0]->name, "blah");

($node) = $selector->select('//parent[2]');
ok($node->attributes->{attr});
($node) = $selector->select('//parent[@attr]');
ok($node->attributes->{attr});
($node) = $selector->select('//parent[@attr="val"]');
ok($node->attributes->{attr});
# this tests predicates support within C library
# note the quotes
($node) = $selector->select('/parent[@attr="val"]'); 
ok($node->attributes->{attr});
($node) = $selector->select('/parent[@attr=\'val\']'); 
ok($node->attributes->{attr});
($node) = $selector->select('/parent[@attr=val]/blah'); # this tests predicates support within C library
is ($node->value, "SECOND");
($node) = $selector->select('/qtest[@qattr="&quot;qval&quot;"]'); # this tests predicates support within C library
is ($node->value, "TEST");
($node) = $selector->select('//qtest[@qattr="&quot;qval&quot;"]');
is ($node->value, "TEST");

is($selector->context->operators->{'+'}->(5, 6), 11);
is($selector->context->operators->{'-'}->(6, 5), 1);
is($selector->context->operators->{'and'}->(1, 0), 0);
is($selector->context->operators->{'and'}->(1, 1), 1);
is($selector->context->operators->{'mod'}->(5, 4), 1);
is($selector->context->operators->{'div'}->(10, 2), 5);
