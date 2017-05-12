#!/usr/bin/env perl

use strict;
use warnings;

use Tree;
use Tree::Persist;

# ---------------------------------------------

sub report_tree
{
	my($depth, $tree, $stack) = @_;

	push @$stack, ':--' x $depth . $tree -> value;
	push @$stack, map{@{report_tree($depth + 1, $_, [])} } $tree -> children;

	return $stack;

} # End of report_tree.

# ---------------------------------------------

# Create a tree:

my($tree_1) = Tree -> new('A') -> add_child
(
	Tree -> new('"B"'),
	Tree -> new("'C'") -> add_child
	(
		Tree -> new('<D>'),
	),
	Tree -> new('>>>E<<<'),
);

print "Tree before writing: \n";
print join("\n", @{report_tree(0, $tree_1, [])}), "\n";

# Create a datastore:

my($writer) = Tree::Persist -> create_datastore
({
	filename => 'scripts/store.xml',
	tree     => $tree_1,
	type     => 'File',
});

# Retrieve tree:

my($reader) = Tree::Persist -> connect
({
	filename => 'scripts/store.xml',
	type     => 'File',
});

my($tree_2) = $reader -> tree;

print "Tree after reading: \n";
print join("\n", @{report_tree(0, $tree_2, [])}), "\n";
