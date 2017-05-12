package dtRdr::Note;
$VERSION = eval{require version}?version::qv($_):$_ for(0.10.1);

use warnings;
use strict;

use base 'dtRdr::Annotation::Range';

use dtRdr::Annotation::Trait::Boundless;

use Class::Accessor::Classy;
rw 'content';
no  Class::Accessor::Classy;

use constant {ANNOTATION_TYPE => 'note'};

=head1 NAME

dtRdr::Note - notes attached to locations

=head1 SYNOPSIS

=cut

# see base classes for most functionality

=head2 references

Get the references attribute.

  my @id_list = $nt->references;

=cut

sub references {
  my $self = shift;
  $self->{references} or return();
  return(@{$self->{references}});
} # end subroutine references definition
########################################################################

=head2 set_references

  $nt->set_references(@id_list);

=cut

sub set_references {
  my $self = shift;
  my @list = @_;
  $self->{references} = [@list];
} # end subroutine set_references definition
########################################################################

=head2 augment_serialize

  my %props = $nt->augment_serialize;

=cut

sub augment_serialize {
  my $self = shift;

  my @refs = $self->references;
  return(
    (scalar(@refs) ? (references => [@refs]) : ()),
  );
} # end subroutine augment_serialize definition
########################################################################

=head2 augment_deserialize

  %props_out = dtRdr::Note->augment_deserialize(%props_in);

=cut

sub augment_deserialize {
  my $package = shift;
  my %props = @_;

  return(
    ($props{references} ?
      (references => [@{$props{references}}]) : ()
    ),
  );
} # end subroutine augment_deserialize definition
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
