#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2023 -- leonerd@leonerd.org.uk

use v5.26;
use warnings;
use Object::Pad 0.800;

package Text::Treesitter::Tree 0.12;
class Text::Treesitter::Tree
   :strict(params);

require Text::Treesitter::_XS;
require Text::Treesitter::Node;

require Encode;

=head1 NAME

C<Text::Treesitter::Tree> - holds the result of a F<tree-sitter> parse operation

=head1 SYNOPSIS

Usually accessed indirectly, via C<Text::Treesitter>.

   use Text::Treesitter;

   my $ts = Text::Treesitter->new(
      lang_name => "perl",
   );

   my $tree = $ts->parse_string( $input );

   my $root = $tree->root_node;

   ...

=head1 DESCRIPTION

Instances of this class represent the result of a parse operation from an
instance of L<Text::Treesitter::Parser>. These objects are not created
directly, but are returned by the C<parse_string> method on a parser instance.

=cut

field $tree :param;
field $text :param :reader;

=head1 METHODS

=head2 text

   $text = $tree->text;

Returns the original source text that was parsed to create the tree.

=cut

=head2 byte_to_char

   $charpos = $tree->byte_to_char( $bytepos );

Returns a position in characters (e.g. such that C<substr> or C<length>
would count), corresponding to a position in the source text counted in bytes
(such as returned by a Node's C<start_bytes> or C<end_bytes> accessor.

=cut

field $_text_bytes;
field %_byte_to_char;
method byte_to_char ( $bytecount )
{
   return $_byte_to_char{$bytecount} //= do {
      $_text_bytes //= Encode::encode_utf8( $text );

      # TODO: This can be done incrementally by finding the largest known
      # precached position before $bytecount
      length( Encode::decode_utf8( substr $_text_bytes, 0, $bytecount ) );
   };
}

method text_substring ( $start_char, $end_char )
{
   return substr( $text, $start_char, $end_char - $start_char );
}

=head2 root_node

   $node = $tree->root_node;

Returns the root node of the parse tree, as an instance of
L<Text::Treesitter::Node>.

=cut

method root_node ()
{
   return Text::Treesitter::Node->new( node => $tree->_root_node, tree => $self );
}

=head1 TODO

The following C library functions are currently unhandled:

   ts_tree_copy
   ts_tree_root_node_with_offset
   ts_tree_language
   ts_tree_included_ranges
   ts_tree_edit
   ts_tree_get_changed_ranges

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
