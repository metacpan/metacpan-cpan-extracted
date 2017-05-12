package dtRdr::Annotation;
$VERSION = eval{require version}?version::qv($_):$_ for(0.10.1);

use warnings;
use strict;


use dtRdr::Traits::Class qw(claim);

use Class::Accessor::Classy;
ro 'is_fake'; sub set_is_fake {$_[0]->{is_fake} = 1};
rw 'revision';
rw 'create_time';
rw 'mod_time';
ro 'public';
no  Class::Accessor::Classy;

BEGIN {
  package dtRdr::AnnotationMeta::Public;
  use Class::Accessor::Classy;
  with 'new';
  ro 'server';
  ro 'owner';
  rw 'rev';
  no  Class::Accessor::Classy;
} # end dtRdr::AnnotationMeta::Public

=head1 NAME

dtRdr::Annotation - base class for Note, Bookmark, and Highlight objects

=head1 SYNOPSIS

Not much happening here.  See L<dtRdr::Annotation::Range>.

=head1 TYPES

The inheritance and traits isn't very easily drawn.  This is about the
best a 2D picture can get.

                 Range  <-- Location (start, end)
                   |
  Annotation    Selection
    \             /
     \           /
      \         /
       \       /
    Annotation::Range
      |-- Highlight
      |-- Note     (+ Annotation::Trait::Boundless)
      |-- Bookmark (+ Annotation::Trait::Boundless)
      `-- AnnoSelection

Currently, all annotations are range-based.  Point-based annotations
would be derived from dtRdr::Location, but we haven't found a use for
those yet.

=cut

=head1 Identifier Methods

=head2 IS_RANGE_TYPE

Required for all annotations.  Any annotation derived from this
class is a range type, so this is just a constant.

=cut

use constant {IS_RANGE_TYPE => 0};

=head2 ANNOTATION_TYPE

Must be implemented by subclasses.

=cut


=head2 make_public

  $anno->make_public(
    owner  => $owner_id,
    server => $server_id,
    rev    => $server_revision
  );

=cut

sub make_public {
  my $self = shift;
  $self->{public} = dtRdr::AnnotationMeta::Public->new(@_);
} # end subroutine make_public definition
########################################################################

=head2 is_mine

Returns true if the annotation is owned by you (whether public or local.)

  my $is = $anno->is_mine;

=cut

sub is_mine {
  my $self = shift;
  my $p = $self->public;
  return(not ($p and defined($p->owner)));
} # end subroutine is_mine definition
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
