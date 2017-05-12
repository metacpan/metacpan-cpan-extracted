package dtRdr::GUI::Wx::State;
$VERSION = eval{require version}?version::qv($_):$_ for(0.10.1);

use warnings;
use strict;
use Carp;


=head1 NAME

dtRdr::GUI::Wx::State - an object to hold state

=head1 SYNOPSIS

=cut

use dtRdr::Accessor;
dtRdr::Accessor->rw qw(
  sidebar_position
  sidebar_open
  notebar_position
  notebar_open
);

=head2 new

  my $state = dtRdr::GUI::Wx::State->new(arg => $val);

=cut

sub new {
  my $package = shift;
  (@_ % 2) and croak('odd number of elements in argument hash');
  my (%args) = @_;

  my $class = ref($package) || $package;
  my $self = {%args};
  bless($self, $class);
  return($self);
} # end subroutine new definition
########################################################################

=head2 negate

  $state->negate($attribute);

=cut

sub negate {
  my $self = shift;
  my ($att) = @_;

  my $setter = 'set_' . $att;
  my $getter = 'get_' . $att;
  $self->can($_) or croak("cannot $_") for($getter, $setter);

  $self->$setter(! $self->$getter);
} # end subroutine negate definition
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
