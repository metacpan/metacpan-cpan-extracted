package dtRdr::String::Splicer;
$VERSION = eval{require version}?version::qv($_):$_ for(0.10.1);

use warnings;
use strict;
use Carp;

use Class::Accessor::Classy;
ro 'position';
rw '_string';
rw '_remstring';
no  Class::Accessor::Classy;

=head1 NAME

dtRdr::String::Splicer - substr that skips spaces

=head1 SYNOPSIS

This applies our string indexing convention to a string without
modifying the original content (other than where you said to insert
something.)

The offsets are always relative to the start of the original string,
regardless of the amount of insertions.  This means that progression
must go only forward.

Leading spaces don't count.  All other spaces count as one character.

=cut


=head2 new

  my $splicer = dtRdr::String::Splicer->new($str);

=cut

sub new {
  my $package = shift;
  my ($string) = @_;
  my $class = ref($package) || $package;
  my $self = {_string => '', _remstring => $string, position => 0};
  bless($self, $class);
  return($self);
} # end subroutine new definition
########################################################################

=head2 insert

  my $count = $splicer->insert($position, $string);

=cut

sub insert {
  my $self = shift;
  my ($pos, $str) = @_;

  ($pos >= $self->position) or croak("cannot go backward");

  $pos -= $self->position;

  0 and warn join("|", map({length($_)} $self->_string, $self->_remstring));
  0 and warn "$pos in ", join("|", map({"'$_'"} $self->_string, $self->_remstring));
  my $rstr = $self->_remstring;
  my $off = 0;
  if($pos) {
    if($rstr =~ m/((?:\s+|[^\s]){$pos})/s) {
      defined($1) or warn "eek";
      $off = $+[0];
    }
    else {
      die "no match"; # I hope we don't hit that
    }
  }
  my $chunk = substr($rstr, 0, $off, '');
  defined($chunk) or warn "ack";
  $self->set__remstring($rstr);
  $self->{_string} .= $chunk . $str;
  $self->{position} += $pos;
  return(length($str));
} # end subroutine insert definition
########################################################################

=head2 string

Get a finished string.

  my $string = $splicer->string;

=cut

sub string {
  my $self = shift;

  0 and warn join("|", map({length($_)} $self->_string, $self->_remstring));
  return($self->_string . $self->_remstring);
} # end subroutine string definition
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
