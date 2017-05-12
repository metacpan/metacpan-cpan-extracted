#!/usr/bin/env perl

use strict;
use warnings;

use Tree::Binary;
use Tree::Binary::Visitor::BreadthFirstTraversal;
use Tree::Binary::Visitor::InOrderTraversal;
use Tree::Binary::Visitor::PreOrderTraversal;
use Tree::Binary::Visitor::PostOrderTraversal;

# ---------------

# A tree representaion of the expression:
#     ( (2 + 2) * (4 + 5) )

my($btree) = Tree::Binary -> new('*')
				-> setLeft
					(
						Tree::Binary -> new('+')
							-> setLeft(Tree::Binary->new('2') )
							-> setRight(Tree::Binary->new('2') )
					)
				-> setRight
					(
						Tree::Binary->new('+')
							-> setLeft(Tree::Binary->new('4') )
							-> setRight(Tree::Binary->new('5') )
					);

# Or shown visually:
#     +---(*)---+
#     |         |
#  +-(+)-+   +-(+)-+
#  |     |   |     |
# (2)   (2) (4)   (5)

# There is no method which will display the above,
# but a crude tree-printer follows.

my($parent_depth);

$btree -> traverse
(
	sub
	{
		my($tree) = @_;

		print "\t" x $tree -> getDepth, $tree -> getNodeValue, "\n";
	}
);

# Get a InOrder visitor.

my($visitor) = Tree::Binary::Visitor::InOrderTraversal -> new;

$btree -> accept($visitor);

# Print the expression in infix order.

print join(' ', $visitor -> getResults), "\n"; # Prints '2 + 2 * 4 + 5'.

# Get a PreOrder visitor.

$visitor = Tree::Binary::Visitor::PreOrderTraversal -> new;

$btree -> accept($visitor);

# Print the expression in prefix order.

print join(' ', $visitor -> getResults), "\n"; # Prints '* + 2 2 + 4 5'.

# Get a PostOrder visitor.

$visitor = Tree::Binary::Visitor::PostOrderTraversal -> new;

$btree -> accept($visitor);

# Print the expression in postfix order.

print join(' ', $visitor -> getResults), "\n"; # Prints "2 2 + 4 5 + *'.

# Get a BreadthFirst visitor.

$visitor = Tree::Binary::Visitor::BreadthFirstTraversal -> new;

$btree -> accept($visitor);

# Print the expression in breadth first order.

print join(' ', $visitor -> getResults), "\n"; # Prints '* + + 2 2 4 5'.

# Be sure to clean up all circular references.
# Of course, since we're exiting immediately, this particular program
# does not need such a defensive manoeuvre.

$btree -> DESTROY();

