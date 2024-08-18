# This class is contained within Tree::RB::XS, mostly within XS
# PODNAME: Tree::RB::XS::Node
require Tree::RB::XS;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tree::RB::XS::Node

=head1 SYNOPSIS

  my $node= $tree->get_node('x');
  my $node= $tree->nth(4);
  
  $node->value(7);
  $node->value++;
  
  $node->mark_newest if $node->recent_tracked;
  
  $node->prune if $node->tree && $node->key =~ /foo/;

=head1 DESCRIPTION

Node objects represent an internal node of the Red/Black tree.  A tree node exists as lightweight
C struct until you access it from Perl, at which time it inflates to become a blessed hashref
object.  This object does not hold a strong reference to the tree; if the tree goes out of scope,
the node object remains but no longer has a relation to other nodes.

Nodes can only be created by a tree, and cannot be re-inserted once pruned.

=head1 ATTRIBUTES

=head2 key

The sort key.  Read-only.  (but if you supplied a reference and you modify what it
points to, you will break the sorting of the tree, so don't do that)

=head2 value

The data associated with the node.  Read/Write.

=head2 index

The integer position of this node within its tree, as if the tree were an array.

=head2 prev

The previous node in the sequence of keys.  Alias C<predecessor> for C<Tree::RB::Node> compat.

=head2 next

The next node in the sequence of keys.  Alias C<successor> for C<Tree::RB::Node> compat.

=head2 recent_tracked

Returns whether node has its insertion order tracked, or not.  This attribute can also be
written.  Disabling recent_tracked removes it from the list of insertion order.  Enabling
recent_tracked causes the node to be placed as the newest inserted node, the same as
L</mark_newest>.

=head2 mark_newest

Promote this node to the end of the insertion-order tracking list as if it has just been
inserted.

=head2 older

  $older= $node->older;
  $node->older($insert_before);

The previous node in insertion-order.  Always C<undef> unless node is L</recent_tracked>.
When written, it places that node before this node in the "recent" list.

=head2 newer

  $older= $node->newer;
  $node->newer($insert_after);

The next node in insertion-order.  Always C<undef> unless node is L</recent_tracked>.
When written, it places that node after this node in the "recent" list.

=head2 tree

The tree this node belongs to.  This becomes C<undef> if the tree is freed or if the node
is pruned from the tree.

=head2 left

The left sub-tree.

=head2 left_leaf

The left-most leaf of the sub-tree.  Alias C<min> for C<Tree::RB::Node> compat.

=head2 right

The right sub-tree.

=head2 right_leaf

The right-most child of the sub-tree.  Alias C<max> for C<Tree::RB::Node> compat.

=head2 parent

The parent node, if any.

=head2 color

0 = black, 1 = red.

=head2 count

The number of items in the tree rooted at this node (inclusive).  This becomes 0 if the node
is no longer in the tree.

=head1 METHODS

=head2 prune

Remove this single node from the tree.  The node will still have its key and value,
but all attributes linking to other nodes will become C<undef>, and L</count> becomes
zero.

=head2 strip

Remove all children of this node, optionally calling a callback for each.
For compat with L<Tree::RB::Node/strip>.

=head2 as_lol

Return sub-tree as list-of-lists. (array of arrays rather?)
For compat with L<Tree::RB::Node/as_lol>.

=head2 iter

Shortcut for C<< $node->tree->iter($node) >>.

=head2 rev_iter

Shortcut for C<< $node->tree->rev_iter($node) >>.

=head2 iter_newer

Shortcut for C<< $node->tree->iter_old_to_new($node) >>.

=head2 iter_older

Shortcut for C<< $node->tree->iter_new_to_old($node) >>.

=head1 VERSION

version 0.14

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
