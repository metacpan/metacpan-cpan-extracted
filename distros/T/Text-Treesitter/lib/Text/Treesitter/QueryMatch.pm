#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2023 -- leonerd@leonerd.org.uk

package Text::Treesitter::QueryMatch 0.02;

use v5.14;
use warnings;

require Text::Treesitter;

=head1 NAME

C<Text::Treesitter::QueryMatch> - stores the result of a F<tree-sitter> query pattern match

=head1 SYNOPSIS

   TODO

=head1 DESCRIPTION

Instances of this class are returned from a L<Text::Treesitter::QueryCursor>
to iterate the matches of the most recent query operation.

=cut

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

=head2 captures

   @captures = $match->captures;

Returns a list of Capture instances, in pattern order. Each will be an
instance of a class having the following accessors:

   $capture->node
   $capture->capture_id

=cut

package Text::Treesitter::QueryMatch::_Capture {
   sub new { my $class = shift; bless [ @_ ], $class }
   sub node { shift->[0] }
   sub capture_id { shift->[1] }
}

sub captures
{
   my $self = shift;
   my $count = $self->capture_count;
   return $count unless wantarray;

   my @captures;
   foreach my $i ( 0 .. $count - 1 ) {
      push @captures, Text::Treesitter::QueryMatch::_Capture->new(
         $self->node_for_capture( $i ), $self->index_for_capture( $i ),
      );
   }

   return @captures;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
