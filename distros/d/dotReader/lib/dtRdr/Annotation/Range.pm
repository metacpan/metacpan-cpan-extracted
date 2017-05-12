package dtRdr::Annotation::Range;
$VERSION = eval{require version}?version::qv($_):$_ for(0.10.1);

use warnings;
use strict;
use Carp;


use base 'dtRdr::Annotation';
use base 'dtRdr::Selection';

use Class::Accessor::Classy;
rw 'title';
no  Class::Accessor::Classy;

{
  # a class for search results, currently pretty sparse
  package dtRdr::AnnoSelection;
  our @ISA = qw(dtRdr::Annotation::Range);
  use constant {ANNOTATION_TYPE => 'annoselection'};
}

=head1 NAME

dtRdr::Annotation::Range - range-derived annotations

=head1 SYNOPSIS

=cut

=head1 Identifier Methods

=head2 IS_RANGE_TYPE

Required for all annotations.  Any annotation derived from this
class is a range type, so this is just a constant.

=cut

use constant {IS_RANGE_TYPE => 1};

=head2 ANNOTATION_TYPE

Must be implemented by subclasses.

=cut

=head1 Misc Methods

=head2 renode

Change the node of an annotation object.  The resultant object cannot be
used for serialization.

  my $new_obj = $obj->renode($node, %props);

=cut

sub renode {
  my $self = shift;
  my $node = shift;
  (@_ % 2) and croak('odd number of elements in argument hash');
  my %props = @_;

  my $package = ref($self);
  return($package->create(
    range => $self,
    %props,
    id => $self->id,
    node => $node,
    is_fake => 1, # always set this
  ));
} # end subroutine renode definition
########################################################################


=head2 dummy

Create a new (not unlinked) copy of an object with different properties.

  $new_obj = $obj->dummy(%props);

=cut

sub dummy {
  my $self = shift;
  (@_ % 2) and croak('odd number of elements in argument hash');
  my %props = @_;
  my $package = ref($self);
  my $new_obj = {%$self, %props};
  bless($new_obj, $package);
  return($new_obj);
} # end subroutine dummy definition
########################################################################

=head2 get_book

Overrides the range get_book alias.

  $hl->get_book;

=cut

sub get_book {
  my $self = shift;
  $self->node->book;
} # end subroutine get_book definition
########################################################################

=head1 Serialization

The annotation storage (dtRdr::Annotation::IO) classes expect
annotations objects to support serialize() and deserialize() methods.
These methods transform an object to/from a plain hash reference (i.e.
there are no linked objects, circular references, etc.)

=head2 serialize

Returns a hashref which contains no book object or other circular
references.

  my $plain_hashref = $object->serialize;

=over

=item augment_serialize

A subclass may define this method to add properties to the serialized
hash reference.

  %props = $object->augment_serialize;

=back

=cut

sub _IF_CANS () {
  qw(
    content
    title
    selected
    context
    revision
    create_time
    mod_time
  );
}
sub serialize {
  my $self = shift;
  $self->is_fake and
    croak("cannot serialize a fake (localized) annotation");

  my $get_loc = sub { $_[0]->offset};
  my $get_id  = sub { $_[0]->id};
  my %serializer = (
    book   => $get_id,
    node   => $get_id,
    start  => $get_loc,
    end    => $get_loc,
    id     => sub {$_[0]}, # by definition
    public => sub {return({%{$_[0]}})}, # so long as it stays plain
  );

  my %hash = map({
      my $val = $self->$_;
      defined($val) ? ($_ => $serializer{$_}->($val)) : ()
    }
    keys(%serializer)
  );

  # some special cases
  foreach my $attribute (_IF_CANS) {
    if($self->can($attribute)) {
      $hash{$attribute} = $self->$attribute;
    }
  }

  # generic special case
  if($self->can('augment_serialize')) {
    my %props = $self->augment_serialize;
    $hash{$_} = $props{$_} for(keys(%props));
  }

  # and remember our type
  $hash{type} = ref($self);

  return(\%hash);
} # end subroutine serialize definition
########################################################################

=head2 deserialize

Transform the stripped-down hashref (as returned by serialize()) into a
proper object.

  my $object = MyClass->deserialize($hashref, book => $book);

=over

=item augment_deserialize

May be defined by a subclass to augment the deserialization.  The
returned properties will be added to the arguments to new().

  %props_out = SubClass->augment_deserialize(%props_in);

=back

=cut

sub deserialize {
  my $package = shift;
  my ($hashref, @args) = @_;
  (@args % 2) and croak('odd number of elements in argument hash');
  my %args = @args;

  (ref($hashref) || '' eq 'HASH') or
    croak("'$hashref' is not a hash reference");

  my $book = $args{book};
  defined($book) or croak("must have a book");
  ($hashref->{book} eq $book->id) or croak("wrong book");

  my $node = $hashref->{node};
  defined($node) or croak "no node";
  $node = $book->toc->get_by_id($node);
  defined($node) or die;
  my %deserializer = (
    public => sub { dtRdr::AnnotationMeta::Public->new(%{$_[0]}) },
  );

  my $object = $package->create(
    map({
      ($package->can($_) ? ($_ => $hashref->{$_}) : ())
    } _IF_CANS
    ),
    node  => $node,
    range => [$hashref->{start}, $hashref->{end}],
    id    => $hashref->{id},
    map({exists($hashref->{$_}) ?
          ($_ => $deserializer{$_}->($hashref->{$_})) : ()
      } keys(%deserializer)
    ),
    # generic special case
    ($package->can('augment_deserialize') ?
      ($package->augment_deserialize(%$hashref, book => $book)) : ()
    ),
  );
  return($object);
} # end subroutine deserialize definition
########################################################################

=head2 clone

Creates a (mostly) detatched version of the object.  (use sparingly)

  $obj->clone;

=cut

sub clone {
  my $self = shift;
  my $clone = ref($self)->deserialize(
    $self->serialize, book => $self->book
  );
  return($clone);
} # end subroutine clone definition
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
