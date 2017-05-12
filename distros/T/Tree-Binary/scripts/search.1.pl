#!/usr/bin/env perl

use strict;
use warnings;

use Tree::Binary::Search;

# -----------------------

my($btree) = Tree::Binary::Search -> new;

$btree -> useNumericComparison();

$btree -> insert(5 => 'Five');
$btree -> insert(2 => 'Two');
$btree -> insert(1 => 'One');
$btree -> insert(3 => 'Three');
$btree -> insert(4 => 'Four');
$btree -> insert(9 => 'Nine');
$btree -> insert(8 => 'Eight');
$btree -> insert(6 => 'Six');
$btree -> insert(7 => 'Seven');

# This creates the following tree (showing keys only):
#
#     +-------(5)----------+
#     |                    |
#  +-(2)-+              +-(9)
#  |     |              |
# (1)   (3)-+     +----(8)
#           |     |
#          (4)   (6)-+
#                    |
#                   (7)
#
# There is no method which will display the above,
# but a crude tree-printer follows.

my($parent_depth);

$btree -> getTree -> traverse
(
	sub
	{
		my($tree) = @_;

		print "\t" x $tree -> getDepth, $tree -> getNodeKey, ': ', $tree -> getNodeValue, "\n";
	}
);

$btree -> exists(7); # Returns a true value (1 actually).

$btree -> update(7 => 'Seven (updated)');

$btree -> select(9); # Returns 'Nine'.

$btree -> min_key(); # Returns 1.

$btree -> min(); # Returns 'One'.

$btree -> max_key(); # Return 9.

$btree -> max(); # Returns 'Nine'.

$btree -> delete(5);

# This results in the following tree (showing keys only):
#
#     +-------(6)-------+
#     |                 |
#  +-(2)-+           +-(9)
#  |     |           |
# (1)   (3)-+     +-(8)
#           |     |
#          (4)   (7)
#

$btree -> getTree -> traverse
(
	sub
	{
		my($tree) = @_;

		print "\t" x $tree -> getDepth, $tree -> getNodeKey, ': ', $tree -> getNodeValue, "\n";
	}
);

