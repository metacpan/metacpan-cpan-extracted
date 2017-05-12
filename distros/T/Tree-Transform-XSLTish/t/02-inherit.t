#!perl
package TransformA;{
 use Tree::Transform::XSLTish ':engine';
 use strict;
 use warnings;
 use Tree::XPathEngine;
 use Test::Most;

 engine_factory {
     ok 1,'custom factory called';
     Tree::XPathEngine->new();
 };

 default_rules;

 tree_rule match => '*', action => sub {
     return $_[0]->it->name, $_[0]->apply_rules;
 }

}

package TransformB;{
 use base 'TransformA';
 use Tree::Transform::XSLTish;
 use strict;
 use warnings;

 tree_rule match => 'coso1', action => sub {
     return 'sub-coso1';
 };

 tree_rule match => 'base/coso2', action => sub {
     return 'sub-coso2';
 }

}

package main;
use Test::Most tests=>2,'die';
use strict;
use warnings;
use Tree::DAG_Node::XPath;

my $tree=Tree::DAG_Node::XPath->new();
$tree->name('base');
$tree->new_daughter->name("coso$_") for 1..5;

{
my $trans=TransformB->new();
my @results=$trans->transform($tree);
is_deeply \@results,[qw(base sub-coso1 sub-coso2 coso3 coso4 coso5)];
}
