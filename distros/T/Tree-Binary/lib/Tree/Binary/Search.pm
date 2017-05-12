
package Tree::Binary::Search;

use strict;
use warnings;

use Scalar::Util qw(blessed);

use Tree::Binary::Search::Node;

use constant TRUE  => 1;
use constant FALSE => 0;

use constant EQUAL_TO     =>  0;
use constant LESS_THAN    => -1;
use constant GREATER_THAN =>  1;

our $VERSION = '1.08';

## ----------------------------------------------------------------------------
## Tree::Binary::Search
## ----------------------------------------------------------------------------

### constructor

sub new {
	my ($_class, $root) = @_;
	my $class = ref($_class) || $_class;
	my $binary_search_tree = {};
	bless($binary_search_tree, $class);
	$binary_search_tree->_init($root);
	return $binary_search_tree;
}

### ---------------------------------------------------------------------------
### methods
### ---------------------------------------------------------------------------

## ----------------------------------------------------------------------------
## private methods

sub _init {
	my ($self, $root) = @_;
    $self->{_root} = $root || "Tree::Binary::Search::Node";
    $self->{_comparison_func} = undef;
}

sub _compare {
    my ($self, $current_key, $btree_key) = @_;
    my $result = $self->{_comparison_func}->($btree_key, $current_key);
    # catch non-numeric values here
    # as well as numbers that are not
    # within our acceptable range
    ($result =~ /\d/ && ($result >= LESS_THAN && $result <= GREATER_THAN))
        || die "Bad Value : got a bad value from the comparison function ($result)";
    return $result;
}

## ----------------------------------------------------------------------------
## mutators

sub useStringComparison {
    my ($self) = @_;
    $self->{_comparison_func} = sub { $_[0] cmp $_[1] };
}

sub useNumericComparison {
    my ($self) = @_;
    $self->{_comparison_func} = sub { $_[0] <=> $_[1] };
}

sub setComparisonFunction {
    my ($self, $func) = @_;
    (ref($func) eq "CODE")
        || die "Incorrect Object Type : comparison function is not a function";
    $self->{_comparison_func} = $func;
}

## ----------------------------------------------------------------------------
## accessors

sub getTree {
    my ($self) = @_;
    return $self->{_root};
}

## ----------------------------------------------------------------------------
## informational

sub isEmpty {
    my ($self) = @_;
    return (ref($self->{_root})) ? FALSE : TRUE;
}

## ----------------------------------------------------------------------------
## methods for underlying tree

sub accept {
    my ($self, $visitor) = @_;
    $self->{_root}->accept($visitor);
}

sub size {
    my ($self) = @_;
    return $self->{_root}->size();
}

sub height {
    my ($self) = @_;
    return $self->{_root}->height();
}

sub DESTROY {
    my ($self) = @_;
    # be sure to call call the DESTROY method
    # on the underlying tree to ensure it is
    # cleaned up properly
    ref($self->{_root}) && $self->{_root}->DESTROY();
}

## ----------------------------------------------------------------------------
## search methods

sub insert {
    my ($self, $key, $value) = @_;
    my $btree;
    if (defined $key && defined $value) {
        $btree = $self->{_root}->new($key, $value);
    }
    elsif (!defined $value &&
           (blessed($key) && $key->isa("Tree::Binary::Search::Node"))) {
        $btree = $key;
    }
    else {
        die "Insufficient Arguments : bad arguments to insert";
    }
    # if the root is not a reference, then
    # we dont yet have a root, so ...
    if ($self->isEmpty()) {
        (defined($self->{_comparison_func}))
            || die "Illegal Operation : No comparison function set";
        $self->{_root} = $btree;
    }
    else {
        my $current = $self->{_root};
        while (1) {
            my $comparison = $self->_compare($current->getNodeKey(), $btree->getNodeKey());
            # if it is equal to, then throw
            # an exception since you can insert
            # duplicates
            die "Illegal Operation : you cannot insert a duplicate key" if $comparison == EQUAL_TO;
            # otherwise ...
            if ($comparison == LESS_THAN) {
                # if it is less than, then we need
                # to insert it down the left arm of
                # the tree, unless of course we
                # dont have a left arm, in which case
                # we just make one out of these vaules
                if ($current->hasLeft()) {
                    $current = $current->getLeft();
                    next;
                }
                else {
                    $current->setLeft($btree);
                    last;
                }
            }
            elsif ($comparison == GREATER_THAN) {
                # if it is greater than, then we need
                # to insert it down the right arm of
                # the tree, unless of course we
                # dont have a right arm, in which case
                # we just make one out of these vaules
                if ($current->hasRight()) {
                    $current = $current->getRight();
                }
                else {
                    $current->setRight($btree);
                    last;
                }
            }
        }
    }
}

sub update {
    my ($self, $key, $value) = @_;
    (!$self->isEmpty())
        || die "Illegal Operation : Cannot update without first inserting";
    (defined $key && defined $value)
        || die "Insufficient Arguments : Must supply a key to find and a value to update";
    # now go about inserting
    my $current = $self->{_root};
    while (1) {
        my $comparison = $self->_compare($current->getNodeKey(), $key);
        # if it is equal to 0, then we have
        # found out value, and we update it
        if ($comparison == EQUAL_TO) {
            $current->setNodeValue($value);
            last;
        }
        elsif ($comparison == LESS_THAN) {
            # if it is less than, then we need
            # to ...
            ($current->hasLeft()) || die "Key Does Not Exist : the key ($key) does not exist in this tree";
            $current = $current->getLeft();
            next;
        }
        elsif ($comparison == GREATER_THAN) {
            # if it is greater than, then we need
            # to ...
            ($current->hasRight()) || die "Key Does Not Exist : the key ($key) does not exist in this tree";
            $current = $current->getRight();
            next;
        }
    }
}

sub select : method {
    my ($self, $key) = @_;
    (!$self->isEmpty())
        || die "Illegal Operation : Cannot lookup anything without first inserting";
    (defined $key)
        || die "Insufficient Arguments : Must supply a key to find";

    my $current = $self->{_root};
    while (1) {
        my $comparison = $self->_compare($current->getNodeKey(), $key);
        if ($comparison == EQUAL_TO) {
            # if it is equal to, then we are
            # have found it, so return
            last;
        }
        elsif ($comparison == LESS_THAN) {
            # if it is less than, then we need
            # to look down the left arm of
            # the tree, unless of course we
            # dont have a left arm, in which case
            # we just die
            ($current->hasLeft()) || die "Key Does Not Exist : the key ($key) does not exist in this tree";
            $current = $current->getLeft();
            next;
        }
        elsif ($comparison == GREATER_THAN) {
            # if it is greater than, then we need
            # to look down the right arm of
            # the tree, unless of course we
            # dont have a right arm, in which case
            # we just dies
            ($current->hasRight()) || die "Key Does Not Exist : the key ($key) does not exist in this tree";
            $current = $current->getRight();
            next;
        }
    }
    return $current->getNodeValue();
}

sub exists : method {
    my ($self, $key) = @_;
    (defined $key)
        || die "Insufficient Arguments : Must supply a key to find";
    return FALSE if $self->isEmpty();

    my $current = $self->{_root};
    while (1) {
        my $comparison = $self->_compare($current->getNodeKey(), $key);
        if ($comparison == 0) {
            # if it is equal to, then we are
            # have found it, so return TRUE
            return TRUE;
        }
        elsif ($comparison == -1) {
            # if it is less than, then we need
            # to look down the left arm of
            # the tree, unless of course we
            # dont have a left arm, in which case
            # we just return FALSE
            ($current->hasLeft()) || return FALSE;
            $current = $current->getLeft();
            next;
        }
        elsif ($comparison == 1) {
            # if it is greater than, then we need
            # to look down the right arm of
            # the tree, unless of course we
            # dont have a right arm, in which case
            # we just return FALSE
            ($current->hasRight()) || return FALSE;
            $current = $current->getRight();
            next;
        }
    }
}

sub _max_node {
    my ($self) = @_;
    (!$self->isEmpty())
        || die "Illegal Operation : Cannot get a max without first inserting";
    my $current = $self->{_root};
    $current = $current->getRight() while $current->hasRight();
    return $current;
}

sub _min_node {
    my ($self) = @_;
    (!$self->isEmpty())
        || die "Illegal Operation : Cannot get a min without first inserting";
    my $current = $self->{_root};
    $current = $current->getLeft() while $current->hasLeft();
    return $current;
}

sub max_key {
    my ($self) = @_;
    return $self->_max_node()->getNodeKey();
}

sub min_key {
    my ($self) = @_;
    return $self->_min_node()->getNodeKey();
}

sub max {
    my ($self) = @_;
    return $self->_max_node()->getNodeValue();
}

sub min {
    my ($self) = @_;
    return $self->_min_node()->getNodeValue();
}

## ------------------------------------------------------------------------
## Delete was pretty much lifted from the description in:
## http://www.msu.edu/~pfaffben/avl/libavl.html/Deleting-from-a-BST.html
## ------------------------------------------------------------------------

sub delete : method {
    my ($self, $key) = @_;
    (!$self->isEmpty())
        || die "Illegal Operation : Cannot delete without first inserting";
    (defined($key))
        || die "Insufficient Arguments : you must supply a valid key to lookup in the tree";

    my $current = $self->{_root};
    while (1) {
        my $comparison = $self->_compare($current->getNodeKey(), $key);
        if ($comparison == 0) {
            # if it is equal to,
            if ($current->isLeaf()) {
                # no children at all, then ...
                if ($current->isRoot()) {
                    # if it has no children and is the root
                    # then we need to remove the root, and
                    # replace it with the package name of the
                    # tree the user wants to use
                    $self->{_root} = ref($current);
                    return TRUE;
                }
                else {
                    # otherwise we just want to remove
                    # outselves from the parent
                    $self->_replaceInParent($current);
                    return TRUE;
                }
            }
            else {
                # we know we have at least one child
                # since we are not a leaf node
                if (!$current->hasRight()) {
                    # if we dont have the right, then
                    # we know we have a left (otherwise
                    # we would be a leaf)
                    # remove the left then, then
                    my $left = $current->removeLeft();
                    # remove current from it parent
                    # and replace it with the left
                    $self->_replaceInParent($current, $left);
                    return TRUE;
                }
                # however, if we have a right side, then ...
                else {
                    # remove the right side ...
                    my $right = $current->getRight();
                    # if the right itself has a left then ...
                    if (!$right->hasLeft()) {
                        # remove the right child
                        my $right = $current->removeRight();
                        # set the right child's left (if we have one)
                        $right->setLeft($current->removeLeft()) if $current->hasLeft();
                        # remove current from it parent
                        # and replace it with the right
                        $self->_replaceInParent($current, $right);
                        return TRUE;
                    }
                    else {
			# go to the leftmost node in the right subtree
                        my $inorder_successor = $right;
                        my $current_right;

			do {
                            $current_right = $inorder_successor;
				$inorder_successor = $inorder_successor->getLeft();
			} while ( $inorder_successor->hasLeft() );

                        # now that are here, we can adjust the tree
                        if ($inorder_successor->hasRight()) {
                            $current_right->setLeft($inorder_successor->getRight());
                        }
                        else {
                            $inorder_successor->getParent()->removeLeft();
                        }
                        $inorder_successor->setLeft($current->removeLeft()) if $current->hasLeft();
                        $inorder_successor->setRight($current->removeRight()) if $current->hasRight();
                        $self->_replaceInParent($current, $inorder_successor);
                        return TRUE;
                    }
                }
            }
        }
        elsif ($comparison == -1) {
            # if it is less than, ...
            ($current->hasLeft()) || die "Key Does Not Exist : the key ($key) does not exist in this tree";
            $current = $current->getLeft();
            next;
        }
        elsif ($comparison == 1) {
            # if it is greater than, ...
            ($current->hasRight()) || die "Key Does Not Exist : the key ($key) does not exist in this tree";
            $current = $current->getRight();
            next;
        }
    }
}

# delete helper

sub _replaceInParent {
    my ($self, $tree, $replacement) = @_;
    if ($tree->isRoot()) {
        $replacement->makeRoot();
        $self->{_root} = $replacement;
    }
    else {
        my $parent = $tree->getParent();
        if ($parent->hasLeft() && $parent->getLeft() eq $tree) {
            $parent->removeLeft();
            $parent->setLeft($replacement) if $replacement;
        }
        elsif ($parent->hasRight() && $parent->getRight() eq $tree) {
            $parent->removeRight();
            $parent->setRight($replacement) if $replacement;
        }
    }
}

1;

__END__

=head1 NAME

Tree::Binary::Search - A Binary Search Tree for perl

=head1 SYNOPSIS

The program ships as scripts/search.1.pl:

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

If printing the tree is important, you are better off using
L<Tree::DAG_Node|https://metacpan.org/pod/Tree::DAG_Node#tree2string-options-some_tree>.

=head1 DESCRIPTION

This module implements a binary search tree, which is a specialized usage of a binary tree. The basic principle is that all elements to the left are less than the root, all elements to the right are greater than the root. This reduces the search time for elements in the tree, by halving the number of nodes that need to be searched each time a node is examined.

Binary search trees are a very well understood data-structure and there is a wealth of information on the web about them.

Trees are a naturally recursive data-structure, and therefore, tend to lend themselves well to recursive traversal functions. I however, have chosen to implement the tree traversal in this module without using recursive subroutines. This is partially a performance descision, even though perl can handle theoreticaly unlimited recursion, subroutine calls to have some overhead. My algorithm is still recursive, I have just chosen to keep it within a single subroutine.

=head1 METHODS

=over 4

=item B<new>

The constructor will take an optional argument (C<$root>) which a class (or a class name) which is derived from Tree::Binary::Search::Node. It will then use that class to create all its new nodes.

=back

=head2 Accessors

=over 4

=item B<getTree>

This will return the underlying binary tree object. It is a Tree::Binary::Search::Node hierarchy, but can be something else if you use the optional C<$root> argument in the constructor.

=back

=head2 Informational

=over 4

=item B<isEmpty>

Returns true (C<1>) if the tree is empty, and false (C<0>) otherwise.

=item B<size>

Return the number of nodes in the tree.

=item B<height>

Return the length of the longest path from the root to the furthest leaf node.

=back

=head2 Tree Methods

=over 4

=item B<accept ($visitor)>

This will pass the C<$visitor> object to the underlying Tree::Binary::Search::Node C<accept> method.

=item B<DESTROY>

This will clean up the underlying Tree::Binary object by calling DESTROY on its root node. This is necessary to properly clean up circular references. See the documentation for L<Tree::Binary>, specifically the "CIRCULAR REFERENCES" section for more details.

=back

=head2 Comparison Functions

=over 4

=item B<useNumericComparison>

A comparison function needs to be set for a Tree::Binary::Search object to work. This implementes numeric key comparisons.

=item B<useStringComparison>

A comparison function needs to be set for a Tree::Binary::Search object to work. This implementes string key comparisons.

=item B<setComparisonFunction ($CODE)>

A comparison function needs to be set for a Tree::Binary::Search object to work. You can set your own here. The comparison function must return one of three values; -1 for less than, 0 for equal to, and 1 for greater than. The constants EQUAL_TO, GREATER_THAN and LESS_THAN are implemented in the Tree::Binary::Search package to help this.

=back

=head2 Search Methods

=over 4

=item B<insert ($key, $value)>

Inserts the C<$value> at the location for C<$key> in the tree. An exception will be thrown if either C<$key> or C<$value> is undefined. Upon insertion of the first element, we check to be sure a comparison function has been assigned. If one has not been assigned, an exception will be thrown.

=item B<update ($key, $value)>

Updates the C<$value> at the location for C<$key> in the tree. If the key is not found, and exception will be thrown. An exception will also be thrown if either C<$key> or C<$value> is undefined, or if no keys have been inserted yet.

=item B<exists ($key)>

Returns true (C<1>) if the C<$key> specified is found, returns false (C<0>) othewise. An exception will be thrown if C<$key> is undefined, and it will return false (C<0>) if no keys have been inserted yet.

=item B<select ($key)>

Finds and returns the C<$key> specified. If the key is not found, and exception will be thrown. An exception will also be thrown if C<$key> is undefined, or if no keys have yet been inserted.

=item B<delete ($key)>

Deletes the node at C<$key> in the tree, and restructures the tree appropriately. If the key is not found, and exception will be thrown. An exception will also be thrown if C<$key>  is undefined, or if no keys have been inserted yet.

Deletion in binary search trees is difficult, but as with most things about binary search trees, it has been well studied. After a few attempts on my own, I decided it was best to look for a real implementation and use that as my basis. I found C code for the GNU libavl (L<http://www.msu.edu/~pfaffben/avl/libavl.html/Deleting-from-a-BST.html>) online along with an excellent description of the code, so I pretty much copied this implementation directly from the code in this library.

=item B<max_key>

Returns the maximum key stored in the tree (basically the right most node).

=item B<max>

Returns the maximum value stored in the tree (basically the right most node).

=item B<min_key>

Returns the minimum key stored in the tree (basically the left most node).

=item B<min>

Returns the minimum value stored in the tree (basically the left most node).

=back

=head1 OTHER TREE MODULES

There are a number of advanced binary search tree-ish modules on CPAN, they are listed below for your reference. Tree::Binary::Search is not a balanced tree, which may not fit your needs, most of the trees below are balanced in one way or another.

=over 4

=item B<Tree::RedBlack>

This is an implementation of a red-black tree which is a type of balanced binary tree (to the best of my knowledge that is, I am sure I am simplifying it). Tree::Binary::Search does not attempt to balance the tree, so if you are looking for a balanced tree, you might try this.

=item B<Tree::BPTree>

This module implements a B+ tree, rather than a binary search tree. In the authors own words, "B+ trees are balanced trees which provide an ordered map from keys to values. They are useful for indexing large bodies of data. They are similar to 2-3-4 Trees and Red-Black Trees. This implementation supports B+ trees using an arbitrary n value." I am not quite sure exactly how a B+ Tree works, but I am intrigued but this module. It seems to me to be well tested module as well. If you are looking for a B+ Tree, I suggest giving it a look.

=item B<Tree::M>

In its own words, this module "implement M-trees for efficient 'metric/multimedia-searches". From what I can tell, this module is not a b-tree (binary search tree), but an m-tree, which is a tree optimized to handle multi-dimensional (spatial) data, such as latitude and longitude. It is a wrapper around a C++ library.

=item B<Tree::FP>

In the authors own words, "Tree:FP is a Perl implmentation of the FP-Tree based association rule mining algorithm (association rules == market basket analysis)". For a detailed explanation, see "Mining Frequent Patterns without Candidate Generation" by Jiawei Han, Jian Pei, and Yiwen Yin, 2000. Contrarywise, most books on data mining will have information on this algorithm. " While it sounds like a very cool thing, it is not a binary search tree".
=item B<Tree::Ternary>

This is a ternary search trees, as opposed to a binary search tree. Similar, but different. If two nodes are not enough for you, I suggest taking a look at this. These is also an XS based implementation B<Tree::Ternary_XS>.

=item B<Tree>

This is actually the only module I found on CPAN which seems to implement a Binary Search Tree. However, this module was uploaded in October 1999 and as far as I can tell, it has ever been updated (the file modification dates are 05-Jan-1999). There is no actual file called Tree.pm, so CPAN can find no version number. It has no MANIFEST, README of Makefile.PL, so installation is entirely manual. Its documentation is scarce at best, some of it even appears to have been written by Mark Jason Dominus, as far back as 1997 (possibly the source code from an old TPJ article on B-Trees by him).

=back

=head1 SEE ALSO

This module is part of a larger group, which are listed below.

=over 4

=item L<Tree::Binary>

=item L<Tree::Binary::VisitorFactory>

=item L<Tree::Binary::Visitor::BreadthFirstTraversal>

=item L<Tree::Binary::Visitor::PreOrderTraversal>

=item L<Tree::Binary::Visitor::PostOrderTraversal>

=item L<Tree::Binary::Visitor::InOrderTraversal>

=back

=head1 BUGS

None that I am aware of. Of course, if you find a bug, let me know, and I will be sure to fix it.

=head1 CODE COVERAGE

See the CODE COVERAGE section of L<Tree::Binary> for details.

=head1 SEE ALSO

The algorithm for C<delete> was taken from the GNU libavl 2.0.1, with modifications made to accomidate the OO-style of this module.

L<http://www.msu.edu/~pfaffben/avl/libavl.html/Deleting-from-a-BST.html>

=head1 ACKNOWLEDGEMENTS

=over 4

=item Thanks to Jan Kratochvil for the min_key() and max_key() methods.

=back

=head1 Repository

L<https://github.com/ronsavage/Tree-Binary>

=head1 AUTHOR

stevan little, E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004, 2005 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
