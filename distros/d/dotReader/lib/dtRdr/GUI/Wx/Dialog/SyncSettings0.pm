package dtRdr::GUI::Wx::Dialog::SyncSettings0;
$VERSION = eval{require version}?version::qv($_):$_ for(0.0.1);

use warnings;
use strict;
use Carp;

use wxPerl::Constructors;
use base 'wxPerl::Frame';

=head1 NAME

dtRdr::GUI::Wx::Dialog::SyncSettings0 - layout for sync settings

=head1 SYNOPSIS

Just the layout

=cut


=head2 new

  $thing = Class->new($parent, %opts);

=cut

sub new {
  my $class = shift;
  my ($parent, %opts) = @_;
  my $title = delete($opts{title}) || 'Sync Settings';

  my $self = $class->SUPER::new($parent, $title, %opts);

  $self->_create_children;
  $self->__set_properties;
  $self->__do_layout;

  return($self);
} # end subroutine new definition
########################################################################

=head1 AUTHOR

Eric Wilhelm <ewilhelm at cpan dot org>

http://scratchcomputing.com/

=head1 COPYRIGHT

Copyright (C) 2007 Eric L. Wilhelm and OSoft, All Rights Reserved.

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
