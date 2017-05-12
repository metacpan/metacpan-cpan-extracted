package dtRdr::Annotation::Trait::Boundless;
$VERSION = eval{require version}?version::qv($_):$_ for(0.10.1);

use warnings;
use strict;


BEGIN { # naive traits implementation
  use Exporter;
  *{import} = \&Exporter::import;
  our @EXPORT = qw(
    get_start_pos
    get_end_pos
  );
}

=head1 NAME

dtRdr::Annotation::Trait::Boundless - mixin methods for boundless annotations

=head1 Methods

This overrides the start/end position lookups.  If the actual position
is undefined, the answer will be the start or end RP of the node.

=head2 get_start_pos

  $anno->get_start_pos;

=cut

sub get_start_pos {
  my $self = shift;

  my $o = $self->start->offset;
  return(defined($o) ? $o : 0);
} # end subroutine get_start_pos definition
########################################################################

=head2 get_end_pos

  $anno->get_end_pos;

=cut

sub get_end_pos {
  my $self = shift;

  my $o = $self->end->offset;
  my $node = $self->node;
  return(defined($o) ? $o :
    # BZZT!  the nesty monster attacks!
    $self->book->_NP_to_RP($node, $node->word_end - $node->word_start)
    #$node->word_end
    #$node->word_end - $node->word_start
  );
} # end subroutine get_end_pos definition
########################################################################

=head1 AUTHOR

Eric Wilhelm <ewilhelm at cpan dot org>

http://scratchcomputing.com/

=head1 COPYRIGHT

Copyright (C) 2006 Eric L. Wilhelm and OSoft, All Rights Reserved.

=head1 NO WARRANTY

Absolutely, positively NO WARRANTY, neither express or implied, is
offered with this software.  You use this software at your own risk.  In
case of loss, no person or entity owes you anything whatsoever.  You
have been warned.

=head1 LICENSE

The dotReader(TM) is OSI Certified Open Source Software licensed under
the GNU General Public License (GPL) Version 2, June 1991. Non-encrypted
and encrypted packages are usable in connection with the dotReader(TM).
The ability to create, edit, or otherwise modify content of such
encrypted packages is self-contained within the packages, and NOT
provided by the dotReader(TM), and is addressed in a separate commercial
license.

You should have received a copy of the GNU General Public License along
with this program; if not, write to the Free Software Foundation, Inc.,
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

=cut

# vi:ts=2:sw=2:et:sta
1;
