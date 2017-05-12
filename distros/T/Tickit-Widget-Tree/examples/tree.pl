#!/usr/bin/env perl
use strict;
use warnings;
use Tickit;
use Tickit::Widget::Tree;

my $tree = Tree::DAG_Node->random_network({ max_depth => 20, min_depth => 6, max_children => 3, max_node_count => 5000 }); # Tree::DAG_Node->new;
$tree->name('Root');
$tree->walk_down({ callback => sub { shift->attributes->{open} = 0 } });
$tree->attributes->{open} = 1;
my $n;
$tree->add_daughter($n = Tree::DAG_Node->new({name => 'one'}));
$n->add_daughter(Tree::DAG_Node->new({name => 'one.one'}));
$tree->add_daughter($n = Tree::DAG_Node->new({name => 'two'}));
$n->add_daughter(Tree::DAG_Node->new({name => 'two.one'}));
$n->add_daughter(Tree::DAG_Node->new({name => 'two.two'}));
$n->add_daughter(Tree::DAG_Node->new({name => 'two.three'}));
$n->attributes->{open} = 1;
$tree->add_daughter($n = Tree::DAG_Node->new({name => 'three'}));
$n->add_daughter(Tree::DAG_Node->new({name => "three.$_"})) for qw(one two three four five six seven);
$tree->add_daughter(Tree::DAG_Node->new({name => 'four'}));
# warn "$_\n" for @{$tree->tree2string};
Tickit->new(root => do { my $w = Tickit::Widget::Tree->new(root => $tree); $w->take_focus; $w })->run;

