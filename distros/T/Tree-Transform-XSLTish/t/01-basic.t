#!perl
package BasicTransform;{
 use Tree::Transform::XSLTish;
 use strict;
 use warnings;

 tree_rule match => '/', action => sub {
     return 'root', $_[0]->apply_rules;
 };

 tree_rule match => '*', action => sub {
     return $_[0]->it->name, $_[0]->apply_rules;
 }

}

package OtherTransform;{
 use Tree::Transform::XSLTish;
 use strict;
 use warnings;

 default_rules;

 tree_rule match => 'coso1', action => sub {
     return 'coso1';
 };

 tree_rule match => 'base/coso2', action => sub {
     return 'coso2';
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
my $trans=BasicTransform->new();
my @results=$trans->transform($tree);
is_deeply \@results,[qw(root base coso1 coso2 coso3 coso4 coso5)];
}

{
my $trans=OtherTransform->new();
my @results=$trans->transform($tree);
is_deeply \@results,[qw(coso1 coso2)];
}
