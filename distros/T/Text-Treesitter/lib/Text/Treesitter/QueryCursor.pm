#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2023 -- leonerd@leonerd.org.uk

package Text::Treesitter::QueryCursor 0.04;

use v5.14;
use warnings;

require Text::Treesitter::_XS;

=head1 NAME

C<Text::Treesitter::QueryCursor> - stores the result of a F<tree-sitter> node query

=head1 SYNOPSIS

   TODO

=head1 DESCRIPTION

Instances of this class store the result of performing a query pattern match
operation against the node tree of a parse result. Once executed it will
contain the matched patterns and captured nodes, which can then be queried.

=cut

=head1 CONSTRUCTOR

=cut

=head2 new

   $qc = Text::Treesitter::QueryCursor->new;

Returns a new blank instance.

=cut

=head1 METHODS

=cut

=head2 exec

   $qc->exec( $query, $node );

Performs the query pattern-matching operation by attempting to match node
subtrees from the given (root) node, against patterns defined by the query.

This method does not return a result; instead the matches are stored within
the object itself and can be iterated using L</next_match>.

=head2 next_match

   $match = $qc->next_match;

Returns the next stored match from the most recent L</exec> operation, or
C<undef> if there are no more matches. The match is returned as an instance
of L<Text::Treesitter::QueryMatch>.

=cut

sub exec
{
   my $self = shift;
   my ( $query, $node ) = @_;

   $self->_exec( $query, $node->_node );
}

=head1 TODO

The following C library functions are currently unhandled:

   ts_query_cursor_...
   ts_query_cursor_exec
   ts_query_cursor_did_exceed_match_limit
   ts_query_cursor_match_limit
   ts_query_cursor_set_match_limit
   ts_query_cursor_set_byte_range
   ts_query_cursor_set_point_range
   ts_query_cursor_next_match
   ts_query_cursor_remove_match
   ts_query_cursor_next_capture

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
