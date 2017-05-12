package dtRdr::Selection;
$VERSION = eval{require version}?version::qv($_):$_ for(0.10.1);

use warnings;
use strict;
use Carp;


use dtRdr::Traits::Class qw(claim);

use base 'dtRdr::Range';

use Class::Accessor::Classy;
rw qw(
  selected
  context
);
no  Class::Accessor::Classy;

# we can display this many characters
use constant { limit => 40, };

=head1 NAME

dtRdr::Selection - a public selection object

=head1 SYNOPSIS

  dtRdr::Selection->claim($range);

=cut

=head2 set_selected

Sets the selected string based on the constant limit().  If the string
is longer than limit, the middle will be trimmed.

  $selection->set_selected($string);

=cut

sub set_selected {
  my $self = shift;
  my ($string) = @_;
  my @selected;
  if(length($string) > limit) {
    $selected[0] = substr($string, 0, limit/2);
    $selected[1] = substr($string, -(limit/2));
  }
  else {
    $selected[0] = $string;
  }
  $self->SUPER::set_selected(\@selected);
} # end subroutine set_selected definition
########################################################################

=head2 get_selected_string

Handles the issue of whether the selection is one or two pieces.

  my $string = $selection->get_selected_string;

Returns one of the following:

  undef       -- there is no 'selected' value
  "foo...bar" -- two pieces
  "foo"       -- a one-piece (short) selection

=cut

sub get_selected_string {
  my $self = shift;
  my $selected = $self->selected;
  $selected or return;
  return(join('...', @$selected)) if(defined($selected->[1]));
  return($selected->[0]);
} # end subroutine get_selected_string definition
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
