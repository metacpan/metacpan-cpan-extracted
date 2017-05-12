#!/usr/bin/env perl
use strict;
use warnings;
use Tickit;
use Tickit::Widget::Tree;
use Tickit::Widget::ScrollBox;

my $tree = Tree::DAG_Node->random_network({
	max_depth => 30,
	min_depth => 7,
	max_children => 5,
	max_node_count => 8000
});
$tree->name('Root');
# Start with everything closed apart from the root
$tree->walk_down({ callback => sub { shift->attributes->{open} = 0 } });
$tree->attributes->{open} = 1;

Tickit->new(root => do {
	my $w = Tickit::Widget::Tree->new(root => $tree);
	Tickit::Widget::ScrollBox->new(
		child => $w,
		vertical => 1,
		horizontal => 1
	)
})->run;

