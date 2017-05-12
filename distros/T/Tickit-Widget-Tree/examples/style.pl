#!/usr/bin/env perl
use strict;
use warnings;
use Tickit;
use Tickit::Widget::Tree;
use Tickit::Style;

Tickit::Style->load_style(<<'EOF');
Tree {
 toggle-fg: 'green';
 label-fg: 'red';
 highlight-bg: 'black';
 highlight-fg: 226;
 fg: 'blue';
 b: true;
}
EOF

my $tree = Tree::DAG_Node->random_network({ max_depth => 20, min_depth => 6, max_children => 3, max_node_count => 5000 }); # Tree::DAG_Node->new;
$tree->name('Root');
$tree->walk_down({ callback => sub { shift->attributes->{open} = 0 } });
$tree->attributes->{open} = 1;
Tickit->new(root => do { my $w = Tickit::Widget::Tree->new(root => $tree); $w->take_focus; $w })->run;

