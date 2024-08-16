#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2023-2024 -- leonerd@leonerd.org.uk

use v5.26;
use warnings;
use Object::Pad 0.800;

package Text::Treesitter::Node 0.13;
class Text::Treesitter::Node
   :strict(params);

use List::Util 1.29 qw( pairmap );

require Text::Treesitter::_XS;

=head1 NAME

C<Text::Treesitter::Node> - an element of a F<tree-sitter> parse result

=head1 SYNOPSIS

Usually accessed indirectly, via C<Text::Treesitter::Tree>.

   use Text::Treesitter;

   my $ts = Text::Treesitter->new(
      lang_name => "perl",
   );

   my $tree = $ts->parse_string( $input );

   my $root = $tree->root_node;

   foreach my $node ( $root->child_nodes ) {
      next if $node->is_extra;
      my $name = $node->is_named ? $node->type : '"' . $node->text . '"';

      printf "Node %s extends from line %d to line %d\n",
         $name,
         ( $node->start_point )[0] + 1,
         ( $node->end_point )[0] + 1;
   }

=head1 DESCRIPTION

The result of a parse operation is a tree of nodes represented by instances of
this class, which are all stored in an instance of L<Text::Treesitter::Tree>.
Most of the work of handling the result of a parse operation is done by
operating on these tree nodes.

Note that F<tree-sitter>'s C<struct TSNode> type is a structure directly and
not a pointer to it. Therefore, every time the Perl binding wraps it, it has
to create a new object instance for it. You cannot therefore rely on the
identity of these objects to remain invariant as a means to keep track of a
particular tree node.

=cut

field $node :param;
field $tree :param :reader;

=head1 METHODS

=head2 tree

   $tree = $node->tree;

Returns the L<Text::Treesitter::Tree> instance from which this child node was
obtained.

=head2 text

   $text = $node->text;

Returns the substring of the tree's stored text that is covered by this node.

=cut

method text ()
{
   return $tree->text_substring( $self->start_char, $self->end_char );
}

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

=head2 start_char

=head2 end_char

   $pos = $node->start_char;

   $pos = $node->end_char;

Returns the start and end offset position counted in characters (suitable for
use with C<substr>, C<length>, etc...) rather than plain bytes.

=head2 start_point

   ( $line, $col ) = $node->start_point;

Returns the position in the input text where this node's extent begins, split
into a line and column number (both 0-based; the string is considered to start
at position C<(0, 0)>). Note that the column is counted in bytes, not
characters.

=head2 end_point

   ( $row, $col ) = $node->end_point;

Returns the position in the input text just past where this node's extent
finishes, split into a row (line) and column number (both 0-based).

=head2 start_row

=head2 start_column

=head2 end_row

=head2 end_column

   $row = $node->start_row;
   $row = $node->end_row;

   $col = $node->start_column;
   $col = $node->end_column;

I<Since version 0.11.>

Returns individual fields of the start or end position of the node's extent,
all as 0-based indexes.

These are more efficient if you only need the row or column; use
L</start_point> or L</end_point> if you need both.

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
obtained. Returns C<undef> on the root node.

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

=head2 child_by_field_name

   $child = $node->child_by_field_name( $field_name );

I<Since version 0.07.>

Returns the child node associated with the given field name. This would be the
same as the value found by

   my %children = $node->field_names_with_child_nodes;
   $child = $children{ $field_name };

If the node does not have a child with the given field name, an exception is
thrown.

=head2 try_child_by_field_name

   $child = $node->try_child_by_field_name( $field_name );

I<Since version 0.07.>

Similar to L</child_by_field_name> but returns undef if there is no such child
rather than throwing an exception.

=cut

method _node () { $node }

BEGIN {
   use Object::Pad ':experimental(mop)';

   my $mop = Object::Pad::MOP::Class->for_caller;

   foreach my $meth (qw(
         type start_byte end_byte start_point end_point
         start_row start_column end_row end_column
         is_named is_missing is_extra has_error child_count
      )) {

      $mop->add_method( $meth => method () { $node->$meth } );
   }
}

method start_char () { return $tree->byte_to_char( $self->start_byte ) }

method end_char   () { return $tree->byte_to_char( $self->end_byte ) }

method parent ()
{
   my $parent = $node->parent or return undef;
   return Text::Treesitter::Node->new( node => $parent, tree => $tree );
}

method child_nodes ()
{
   return map { Text::Treesitter::Node->new( node => $_, tree => $tree ) } $node->child_nodes;
}

method field_names_with_child_nodes ()
{
   return pairmap { $a => Text::Treesitter::Node->new( node => $b, tree => $tree ) } $node->field_names_with_child_nodes;
}

method child_by_field_name ( $field_name )
{
   my $child = $node->child_by_field_name( $field_name );
   return Text::Treesitter::Node->new( node => $child, tree => $tree )
}

method try_child_by_field_name ( $field_name )
{
   my $child = $node->try_child_by_field_name( $field_name ) or return;
   return Text::Treesitter::Node->new( node => $child, tree => $tree )
}

=head2 debug_sprintf

   $str = $node->debug_sprintf();

Returns a debugging test string that represents the node and all its child
nodes, in a format similar to F<tree-sitter>'s usual S-expr notation.

Basic named nodes are printed with their name in parens; C<(type)>. Anonymous
nodes have their text string in quotes; C<"text">. Child nodes of named are
included within the parens of the type name. Field names are printed as
prefixes with a colon.

   (node)

   (node (children) (go) "here")

   (node left: (node) right: (node))

=cut

method debug_sprintf ()
{
   # Unnamed nodes are just their own text
   if( !$self->is_named ) {
      return sprintf qq("%s"), $self->text =~ s/([\\"])/\\$1/gr;
   }

   my @named_children = $self->field_names_with_child_nodes;

   my $ret = "(" . $self->type;

   while( @named_children ) {
      my $fieldname = shift @named_children;
      my $child     = shift @named_children;

      $ret .= " ";
      $ret .= "$fieldname\: " if defined $fieldname;
      $ret .= $child->debug_sprintf;
   }

   $ret .= ")";

   return $ret;
}

=head1 TODO

The following C library functions are currently unhandled:

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
