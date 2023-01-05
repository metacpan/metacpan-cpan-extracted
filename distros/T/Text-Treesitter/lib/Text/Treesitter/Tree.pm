#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2023 -- leonerd@leonerd.org.uk

package Text::Treesitter::Tree 0.02;

use v5.14;
use warnings;

require Text::Treesitter;

=head1 NAME

C<Text::Treesitter::Tree> - holds the result of a F<tree-sitter> parse operation

=head1 SYNOPSIS

   TODO

=head1 DESCRIPTION

Instances of this class represent the result of a parse operation from an
instance of L<Text::Treesitter::Parser>. These objects are not created
directly, but are returned by the C<parse_string> method on a parser instance.

=cut

=head1 METHODS

=head2 root_node

   $node = $tree->root_node;

Returns the root node of the parse tree, as an instance of
L<Text::Treesitter::Node>.

=cut

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
