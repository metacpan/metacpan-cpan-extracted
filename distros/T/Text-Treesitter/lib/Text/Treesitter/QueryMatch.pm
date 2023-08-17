#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2023 -- leonerd@leonerd.org.uk

use v5.26;
use warnings;
use Object::Pad 0.70;

package Text::Treesitter::QueryMatch 0.10;
class Text::Treesitter::QueryMatch
   :strict(params);

use Carp;

require Text::Treesitter::_XS;

=head1 NAME

C<Text::Treesitter::QueryMatch> - stores the result of a F<tree-sitter> query pattern match

=head1 SYNOPSIS

Usually accessed indirectly, via C<Text::Treesitter::QueryCursor>.

   use Text::Treesitter;
   use Text::Treesitter::QueryCursor;

   my $ts = Text::Treesitter->new(
      lang_name => "perl",
   );

   my $query = $ts->load_query_string( "path/to/query.scm" );

   my $tree = $ts->parse_string( $input );

   my $qc = Text::Treesitter::_QueryCursor->new;

   $qc->exec( $query, $tree->root_node );

   while( my $match = $qc->next_match ) {
      my @captures = $match->captures;

      next unless $query->test_predicates_for_match( $match, \@captures );

      foreach my $capture ( @captures ) {
         my $node = $capture->node;
         my $capturename = $query->capture_name_for_id( $capture->capture_id );

         printf "%s captures the text <%s>\n",
            $capturename, $node->text;
      }
   }

=head1 DESCRIPTION

Instances of this class are returned from a L<Text::Treesitter::QueryCursor>
to iterate the matches of the most recent query operation.

=cut

field $querymatch :param;
field $tree       :param :reader;

ADJUST
{
   defined $querymatch or croak "Require a querymatch";
   defined $tree       or croak "Require a tree";
}

=head1 METHODS

=cut

=head2 pattern_index

   $index = $match->pattern_index;

Returns the index within the query indicating which pattern was responsible
for this match.

=head2 capture_count

   $count = $match->capture_count;

Returns the number of captures made by this pattern.

=cut

BEGIN {
   use Object::Pad ':experimental(mop)';

   my $mop = Object::Pad::MOP::Class->for_caller;

   foreach my $meth (qw(
         pattern_index capture_count
      )) {

      $mop->add_method( $meth => method { $querymatch->$meth( @_ ) } );
   }
}

=head2 captures

   @captures = $match->captures;

Returns a list of Capture instances, in pattern order. Each will be an
instance of a class having the following accessors:

   $capture->node
   $capture->capture_id

=cut

class Text::Treesitter::QueryMatch::_Capture :strict(params) {
   field $node       :param :reader;
   field $capture_id :param :reader;
}

method captures
{
   my $count = $querymatch->capture_count;
   return $count unless wantarray;

   my @captures;
   foreach my $i ( 0 .. $count - 1 ) {
      push @captures, Text::Treesitter::QueryMatch::_Capture->new(
         node       => Text::Treesitter::Node->new( node => $querymatch->node_for_capture( $i ), tree => $tree ),
         capture_id => $querymatch->index_for_capture( $i ),
      );
   }

   return @captures;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
