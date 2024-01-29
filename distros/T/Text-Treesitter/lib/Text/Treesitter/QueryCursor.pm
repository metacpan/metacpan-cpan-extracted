#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2023 -- leonerd@leonerd.org.uk

use v5.26;
use warnings;
use Object::Pad 0.800;

package Text::Treesitter::QueryCursor 0.12;
class Text::Treesitter::QueryCursor
   :strict(params);

use Carp;

require Text::Treesitter::_XS;

=head1 NAME

C<Text::Treesitter::QueryCursor> - stores the result of a F<tree-sitter> node query

=head1 SYNOPSIS

   use Text::Treesitter;
   use Text::Treesitter::QueryCursor;

   my $ts = Text::Treesitter->new(
      lang_name => "perl",
   );

   my $query = $ts->load_query_string( "path/to/query.scm" );

   my $tree = $ts->parse_string( $input );

   my $qc = Text::Treesitter::_QueryCursor->new;

   $qc->exec( $query, $tree->root_node );

   ...

=head1 DESCRIPTION

Instances of this class store the result of performing a query pattern match
operation against the node tree of a parse result. Once executed it will
contain the matched patterns and captured nodes, which can then be queried.

=cut

field $querycursor;
field $_current_tree;
field $_current_query;

ADJUST
{
   $querycursor = Text::Treesitter::_QueryCursor->new;
}

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

=cut

method exec
{
   my ( $query, $node ) = @_;

   $querycursor->_exec( $query, $node->_node );
   $_current_tree = $node->tree;
   $_current_query = $query;
}

=head2 next_match

   $match = $qc->next_match;

Returns the next stored match from the most recent L</exec> operation, or
C<undef> if there are no more matches. The match is returned as an instance
of L<Text::Treesitter::QueryMatch>.

=cut

method next_match
{
   my $querymatch = $querycursor->_next_match or return undef;

   require Text::Treesitter::QueryMatch;
   return Text::Treesitter::QueryMatch->new( querymatch => $querymatch, tree => $_current_tree );
}

=head2 next_match_captures

   $captures = $qc->next_match_captures( %options );

I<Since version 0.10.>

A convenience wrapper around L</next_match> for applying predicate tests and
extracting the nodes corresponding to each capture.

Matches that fail the C<test_predicates_for_match> are skipped. The next match
that passes then has its captures extracted into a hash; with keys of the hash
being the capture names, and the values containing the nodes.

If the C<multi> option is true then each value of the returned hash will be an
array reference containing every node that was captured at that name. If the
option is false then it will contain just the final capture (which is normally
fine because most patterns do not capture multiple nodes).

I<Since version 0.12> the returned captures hash may also contain plain-text
strings that are the result of C<#set!> directives found in the query.

=cut

method next_match_captures ( %options )
{
   my $multi = delete $options{multi};
   keys %options and
      croak "Unrecognised options to ->next_captures: " . join( ", ", keys %options );

   {
      my $match = $self->next_match or return undef;

      my @captures = $match->captures;

      redo unless $_current_query->test_predicates_for_match( $match, \@captures, \my %metadata );

      my %captures_by_name;

      # TODO: What happens on collisions?
      %captures_by_name = %metadata;

      foreach my $capture ( @captures ) {
         my $node = $capture->node;
         my $name = $_current_query->capture_name_for_id( $capture->capture_id );

         if( $multi ) {
            push $captures_by_name{ $name }->@*, $node;
         }
         else {
            $captures_by_name{ $name } = $node;
         }
      }

      return \%captures_by_name;
   }
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
