#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2023 -- leonerd@leonerd.org.uk

package Text::Treesitter::Node 0.03;

use v5.14;
use warnings;

require Text::Treesitter::_XS;

=head1 NAME

C<Text::Treesitter::Node> - an element of a F<tree-sitter> parse result

=head1 SYNOPSIS

   TODO

=head1 DESCRIPTION

The result of a parse operation is a tree of nodes represented by instances of
this class, which are all stored in an instance of L<Text::Treesitter::Tree>.
Most of the work of handling the result of a parse operation is done by
operating on these tree nodes.

=cut

=head1 METHODS

=head2 type

   $type = $node->type;

Returns a description string giving the name of the grammar rule (or directly an
input string for anonymous nodes).

=head2 start_byte

   $pos = $node->start_byte;

Returns the offset into the input string where this node's extent begins

=head2 end_byte

   $pos = $node->end_byte;

Returns the offset into the input string just past where this node's extent
finishes (i.e. the first byte of the input string that is not part of this
node).

=head2 start_point

   ( $line, $col ) = $node->start_point;

Returns the position in the input text where this node's extent begins, split
into a line and column number (both 0-based; the string is considered to start
at position C<(0, 0)>).

=head2 end_point

   ( $line, $col ) = $node->start_point;

Returns the position in the input text just past where this node's extent
finishes, split into a line and column number (both 0-based).

=head2 is_named

   $bool = $node->is_named;

Returns true if the node represents a named rule in the grammar.

=head2 is_missing

   $bool = $node->is_missing;

Returns true if the node was inserted by the parser to recover from certain
kinds of syntax error.

=head2 is_extra

   $bool = $node->is_extra;

Returns true if the node represents something which is not required by the
grammar but could appear anywhere (for example, a comment).

=head2 has_error

   $bool = $node->has_error;

Returns true if the node or any of its descendents represents a syntax error.

=head2 parent

   $parent = $node->parent;

Returns the node's immediate parent; the node from which this node was
obtained.

=head2 child_count

   $count = $node->child_count;

Returns the number of child nodes contained by this one.

=head2 child_nodes

   @nodes = $node->child_nodes;

Returns a list of child nodes. The length of the returned list will the size
given by L</child_count>.

=head2 field_names_with_child_nodes

   @kvlist = $node->field_names_with_child_nodes;

Returns an even-length key/value list containing field names associated with
child nodes. The list will be twice as long as the size given by
L</child_count> and consist of pairs. In each pair, the first value is either
a field name or C<undef> if the node has no field name, and the second is the
child node itself.

On Perl version 5.36 or above, the multi-variable C<foreach> list syntax may
be useful to handle these:

   foreach my ($name, $child) ($node->field_names_with_child_nodes) {
      ...
   }

On earlier version, the L<List::Util> pair functions such as C<pairs> might be
used instead:

   use List::Util 'pairs';

   foreach (pairs $node->field_names_with_child_nodes) {
      my ($name, $child) = @$_;
      ...
   }

=cut

=head1 TODO

The following C library functions are currently unhandled:

   ts_node_child_by_field_name
   ts_node_child_by_field_id
   ts_node_next_sibling
   ts_node_prev_sibling
   ts_node_next_named_sibling
   ts_node_prev_named_sibling
   ts_node_first_child_for_byte
   ts_node_first_named_child_for_byte
   ts_node_descendant_for_byte_range
   ts_node_descendant_for_point_range
   ts_node_named_descendant_for_byte_range
   ts_node_named_descendant_for_point_range
   ts_node_edit
   ts_node_eq

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
