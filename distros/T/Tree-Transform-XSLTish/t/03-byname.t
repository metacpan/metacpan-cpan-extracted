#!perl
package NameTransform;{
 use Tree::Transform::XSLTish;
 use strict;
 use warnings;

 default_rules;

 tree_rule match => 'coso3', action => sub {
     return $_[0]->call_rule('munge');
 };

 tree_rule name => 'munge', action => sub {
     return 'munged-'.$_[0]->it->name;
 };

}

package main;
use Test::Most tests=>1,'die';
use strict;
use warnings;
use Tree::DAG_Node::XPath;

my $tree=Tree::DAG_Node::XPath->new();
$tree->name('base');
$tree->new_daughter->name("coso$_") for 1..5;

{
my $trans=NameTransform->new();
my @results=$trans->transform($tree);
is_deeply \@results,[qw(munged-coso3)];
}
