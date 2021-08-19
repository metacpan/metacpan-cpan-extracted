#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2011-2017 -- leonerd@leonerd.org.uk

package Tickit::Pen 0.72;

use v5.14;
use warnings;

use Carp;

our @ALL_ATTRS = qw( fg bg b u i rv strike af blink );

our @BOOL_ATTRS = qw( b u i rv strike blink );
our @INT_ATTRS  = qw( fg bg af );

# Load the XS code
require Tickit;

=head1 NAME

C<Tickit::Pen> - store a collection of rendering attributes

=head1 DESCRIPTION

A pen instance stores a collection of rendering attributes for text to
display. It comes in two forms, mutable and immutable. Both types of pen are
subclasses of the base C<Tickit::Pen> class.

An immutable pen is an instance of C<Tickit::Pen::Immutable>. Its attributes
are set by the constructor and are fixed thereafter. Methods are provided to
query the presence or value of attributes, and to fetch the entire set as a
hash.

A mutable pen is an instance of C<Tickit::Pen::Mutable>. Its attributes may be
set by the constructor, and can be changed at any time. As well as supporting
the same query methods as immutable pens, more methods are provided to change
or remove them.

While mutable pens may initially seem more useful, they can complicate logic
due to their shared referential nature. If the same mutable pen is shared
across multiple places, care needs to be taken to redraw anything that depends
on it if it is ever changed. If pens need sharing, especially if results are
cached for performance, consider using immutable pens to simplify the logic.

=head2 Attributes

The following named pen attributes are supported:

=over 8

=item fg => COL

=item bg => COL

Foreground or background colour. C<COL> may be an integer or one of the eight
colour names. A colour name may optionally be prefixed by C<hi-> for the
high-intensity version (may not be supported by all terminals). Some terminals
may support a palette of 256 colours instead, some 16, and some only 8. The
pen object will not check this as it cannot be reliably detected in all cases.

=item fg:rgb8 => STRING

=item bg:rgb8 => STRING

Foreground or background colour secondary RGB8 specification. The value is a
string encoding the three 8-bit values in hexadecimal notation, prefixed by a
hash (C<#>) symbol; for example

   #13579B

On input, either lower- or upper-case is accepted; on output the letters will
be upper-case.

These attribute can only be set if the corresponding regular index attribute
is also set. Changing or clearing the regular index will also clear the RGB8
version.

Applications wishing to use this attribute should be aware that the majority
of terminal drivers will not be able to support it, and so should make sure to
set an appropriate regular colour index as well. Some terminals using the
F<xterm> driver may make use of it, however, and therefore ignore the index
version.

=item b => BOOL

=item u => BOOL

=item i => BOOL

=item rv => BOOL

=item strike => BOOL

=item blink => BOOL

Bold, underline, italics, reverse video, strikethrough, blink.

=item af => INT

Alternate font.

=back

Note that not all terminals can render the italics, strikethrough, or
alternate font attributes.

=cut

=head1 CONSTRUCTORS

=cut

=head2 new

   $pen = Tickit::Pen->new( %attrs )

Returns a new pen, initialised from the given attributes.

Currently this method returns a C<Tickit::Pen::Mutable>, though this may
change in a future version. It is provided for backward-compatibility for code
that expects to be able to construct a C<Tickit::Pen> directly.

   $pen = Tickit::Pen::Immutable->new( %attrs )

   $pen = Tickit::Pen::Mutable->new( %attrs )

Return a new immutable, or mutable pen, initialised from the given attributes.

=cut

sub new
{
   my $class = shift;
   my %attrs = @_;

   # Default to mutable for now
   $class = "Tickit::Pen::Mutable" if $class eq __PACKAGE__;

   my $self = $class->_new( \%attrs );
   croak "Unrecognised pen attributes " . join( ", ", sort keys %attrs ) if %attrs;
   return $self;
}

=head2 new_from_attrs

   $pen = Tickit::Pen->new_from_attrs( $attrs )

Returns a new pen, initialised from keys in the given HASH reference. Used
keys are deleted from the hash.

Currently this method returns a C<Tickit::Pen::Mutable>, though this may
change in a future version. It is provided for backward-compatibility for code
that expects to be able to construct a C<Tickit::Pen> directly.

   $pen = Tickit::Pen::Immutable->new_from_attrs( $attrs )

   $pen = Tickit::Pen::Mutable->new_from_attrs( $attrs )

Return a new immutable, or mutable pen, initialised from the given attributes.

=cut

sub new_from_attrs
{
   my $class = shift;
   my ( $attrs ) = @_;

   # Default to mutable for now
   $class = "Tickit::Pen::Mutable" if $class eq __PACKAGE__;

   return $class->_new( $attrs );
}

=head2 as_mutable

=head2 clone

   $pen = $orig->as_mutable

   $pen = $orig->clone

Returns a new mutable pen, initialised by copying the attributes of the
original.

C<clone> is provided as a legacy alias, but may be removed in a future
version.

=cut

sub as_mutable
{
   my $orig = shift;
   return Tickit::Pen::Mutable->new_from_attrs( { $orig->getattrs } );
}
*clone = \&as_mutable;

=head2 as_immutable

   $pen = $orig->as_immutable

Returns an immutable pen, initialised by copying the attributes of the
original. When called on an immutable pen, this method just returns the same
pen instance.

=cut

sub as_immutable
{
   my $orig = shift;
   return Tickit::Pen::Immutable->new_from_attrs( { $orig->getattrs } );
}

=head2 mutable

   $is_mutable = $pen->mutable

Returns true on mutable pens and false on immutable ones.

=cut

=head1 METHODS ON ALL PENS

The following query methods apply to both immutable and mutable pens.

=cut

=head2 hasattr

   $exists = $pen->hasattr( $attr )

Returns true if the given attribute exists on this object

=cut

=head2 getattr

   $value = $pen->getattr( $attr )

Returns the current value of the given attribute

=cut

=head2 getattrs

   %values = $pen->getattrs

Returns a key/value list of all the attributes

=cut

=head2 equiv_attr

   $equiv = $pen->equiv_attr( $other, $attr )

Returns true if the two pens have the equivalent values for the given
attribute; that is, either both define it to the same value, or neither
defines it.

=cut

=head2 equiv

   $equiv = $pen->equiv( $other )

Returns true if the two pens have equivalent values for all attributes.

=cut

=head1 METHODS ON MUTABLE PENS

The following mutation methods exist on mutable pens.

=cut

=head2 chattr

   $pen->chattr( $attr, $value )

Change the value of an attribute. Setting C<undef> deletes the attribute
entirely. See also C<delattr>.

=cut

=head2 chattrs

   $pen->chattrs( \%attrs )

Change the values of all the attributes given in the hash. Recgonised
attributes will be deleted from the hash.

=cut

=head2 delattr

   $pen->delattr( $attr )

Delete an attribute from this pen. This attribute will no longer be modified
by this pen.

=cut

=head2 copy_from

=head2 default_from

   $pen->copy_from( $other )

   $pen->default_from( $other )

Copy attributes from the given pen. C<copy_from> will override attributes
already defined by C<$pen>; C<default_from> will only copy attributes that are
not yet defined by C<$pen>.

As a convenience both methods return C<$pen>.

=cut

sub copy_from
{
   my $self = shift;
   my ( $other ) = @_;
   $self->copy( $other, 1 );
   return $self;
}

sub default_from
{
   my $self = shift;
   my ( $other ) = @_;
   $self->copy( $other, 0 );
   return $self;
}

sub sprintf
{
   my $self = shift;

   return "{" . join( ",", map {
      $self->hasattr($_) ? "$_=" . $self->getattr($_) : ()
   } @ALL_ATTRS ) . "}";
}

use overload
   '""' => sub {
      my $self = shift;
      return ref($self) . $self->sprintf
   },
   bool => sub { 1 };

use Scalar::Util qw( refaddr );
use overload '==' => sub { refaddr($_[0]) == refaddr($_[1]) };

package Tickit::Pen::Immutable 0.72;
use base qw( Tickit::Pen );
use constant mutable => 0;

sub as_immutable { return $_[0] }

package Tickit::Pen::Mutable 0.72;
use base qw( Tickit::Pen );
use constant mutable => 1;

# Adds further methods in XS

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
