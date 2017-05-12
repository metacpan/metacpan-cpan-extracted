#!/usr/bin/env perl

use strict;
use warnings;

use Tree;
#use Tree::DAG_Node;

# ------------------------------------------------

sub tree
{
	my($tree) = Tree -> new('Root');

	$tree -> meta({uid => 0});

	my($count) = 0;

	my(%node);

	for (qw/H I J K L M N O P Q/)
	{
		$node{$_} = Tree -> new($_);

		$node{$_} -> meta({uid => ++$count});

	}

	$tree -> add_child($node{H});
	$node{H} -> add_child($node{I});
	$node{I} -> add_child($node{J});
	$node{H} -> add_child($node{K});
	$node{H} -> add_child($node{L});
	$tree -> add_child($node{M});
	$tree -> add_child($node{N});
	$node{N} -> add_child($node{O});
	$node{O} -> add_child($node{P});
	$node{P} -> add_child($node{Q});

	print map("$_\n", @{$tree -> tree2string});
	print map("$_\n", @{$tree -> tree2string({no_attributes => 1})});

} # End of tree.

# ------------------------------------------------

=pod

sub tree_dag_node
{
	my($tree) = Tree::DAG_Node -> new({name => 'Root'});

	$tree -> attributes({uid => 0});

	my($count) = 0;

	my(%node);

	for (qw/H I J K L M N O P Q/)
	{
		$node{$_} = Tree::DAG_Node -> new({name => $_});

		$node{$_} -> attributes({uid => ++$count});

	}

	$tree -> add_daughter($node{H});
	$node{H} -> add_daughter($node{I});
	$node{I} -> add_daughter($node{J});
	$node{H} -> add_daughter($node{K});
	$node{H} -> add_daughter($node{L});
	$tree -> add_daughter($node{M});
	$tree -> add_daughter($node{N});
	$node{N} -> add_daughter($node{O});
	$node{O} -> add_daughter($node{P});
	$node{P} -> add_daughter($node{Q});

	print map("$_\n", @{$tree -> tree2string});
	print map("$_\n", @{$tree -> tree2string({no_attributes => 1})});

} # End of tree_dag_node.

=cut

# ------------------------------------------------

tree;
#tree_dag_node;
