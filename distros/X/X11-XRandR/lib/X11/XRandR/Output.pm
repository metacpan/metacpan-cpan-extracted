package X11::XRandR::Output;

# ABSTRACT: A video output

use Types::Standard -types;
use Types::Common::Numeric qw[ PositiveOrZeroNum PositiveOrZeroInt ];
use X11::XRandR::Types -types;

use Moo;
use namespace::clean;
use MooX::StrictConstructor;

our $VERSION = '0.01';

use overload '""' => \&to_string;

#pod =attr name
#pod
#pod =cut

has name => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

#pod =attr Border
#pod
#pod An instance of L<X11::XRandR::Border>. Optional.
#pod
#pod =method has_Border
#pod
#pod I<Boolean> True if L</Border> has been specified
#pod
#pod
#pod =cut

has Border => (
    is        => 'ro',
    isa       => InstanceOf ['X11::XRandR::Border'],
    predicate => 1,
);

#pod =attr Clones
#pod
#pod Optional.
#pod
#pod =method has_Clones
#pod
#pod I<Boolean> True if L<Clones> was specified.
#pod
#pod =cut

has Clones => (
    is        => 'ro',
    isa       => ArrayRef [Str],
    predicate => 1,
);

#pod =attr Brightness
#pod
#pod Optional.
#pod
#pod =method has_Brightness
#pod
#pod I<Boolean>  True if L<Brightness> was specified.
#pod
#pod =cut

has Brightness => (
    is        => 'ro',
    isa       => Num,
    predicate => 1,
);

#pod =attr connection
#pod
#pod The state of the connection.  See L<X11::XRandR::Types/Connection> for values.
#pod
#pod =cut

has connection => (
    is       => 'ro',
    isa      => Connection,
    required => 1,
);

#pod =attr CRTC
#pod
#pod The CRTC value.
#pod
#pod =cut

has CRTC => (
    is  => 'ro',
    isa => PositiveOrZeroInt
);

#pod =attr CRTCs
#pod
#pod An array of CRTC values.
#pod
#pod =cut

has CRTCs => (
    is  => 'ro',
    isa => ArrayRef [PositiveOrZeroInt],
);


#pod =attr cur_crtc
#pod
#pod An instance of L<X11::XRandR::CurCrtc>. Optional.
#pod
#pod =method has_cur_crtc
#pod
#pod I<Boolean> True if L</cur_crtc> has been specified
#pod
#pod =cut

has cur_crtc => (
    is        => 'ro',
    isa       => InstanceOf ['X11::XRandR::CurCrtc'],
    predicate => 1,
);

#pod =attr cur_mode
#pod
#pod An instance of L<X11::XRandR::CurMode>. Optional.
#pod
#pod =method has_cur_mode
#pod
#pod I<Boolean> True if L</cur_mode> has been specified
#pod
#pod =cut

has cur_mode => (
    is        => 'ro',
    isa       => InstanceOf ['X11::XRandR::CurMode'],
    predicate => 1,
);

#pod =attr dimension
#pod
#pod An instance of L<X11::XRandR::Dimension>. Optional.
#pod
#pod =method has_dimension
#pod
#pod I<Boolean>  True if L<dimension> was specified.
#pod
#pod =cut

has dimension => (
    is        => 'ro',
    isa       => InstanceOf ['X11::XRandR::Dimension'],
    predicate => 1,
);

#pod =attr Gamma
#pod
#pod An arrayref of floats. Optional.
#pod
#pod =method has_Gamma
#pod
#pod I<Boolean>  True if L<Gamma> was specified.
#pod
#pod =cut

has Gamma => (
    is        => 'ro',
    isa       => Tuple[ PositiveOrZeroNum, PositiveOrZeroNum, PositiveOrZeroNum],
    predicate => 1,
);

#pod =attr Identifier
#pod
#pod =cut

has Identifier => (
    is       => 'ro',
    isa      => PositiveOrZeroInt,
    required => 1,
);

#pod =attr Timestamp
#pod
#pod =cut

has Timestamp => (
    is       => 'ro',
    isa      => PositiveOrZeroInt,
    required => 1,
);

#pod =attr Subpixel
#pod
#pod For values, see L<X11::XRandR::Types/SubPixelOrder>.
#pod
#pod =cut

has Subpixel => (
    is       => 'ro',
    isa      => SubPixelOrder,
    required => 1,
);

#pod =attr rotations
#pod
#pod An array of L<X11::XRandR::Types/Direction> values
#pod
#pod =cut

has rotations => (
    is       => 'ro',
    isa      => ArrayRef [Direction],
    required => 1,
);

#pod =attr reflections
#pod
#pod An array of C<x> and/or C<y> values.
#pod
#pod =cut

has reflections => (
    is       => 'ro',
    isa      => ArrayRef [ Enum[ 'x', 'y' ] ],
    required => 1,
);

#pod =attr modes
#pod
#pod An array of L<X11::XRandR::Mode> objects.
#pod
#pod =method has_modes
#pod
#pod I<Boolean> True if L</modes> was specified.
#pod
#pod =cut

has modes => (
    is        => 'ro',
    isa       => ArrayRef [ InstanceOf ['X11::XRandR::Mode'] ],
    predicate => 1,
);


#pod =attr Panning
#pod
#pod An instance of L<X11::XRandR::Geometry>. Optional.
#pod
#pod =method has_Panning
#pod
#pod I<Boolean> True if L</Panning> was specified.
#pod
#pod =cut

has Panning => (
    is        => 'ro',
    isa       => InstanceOf ['X11::XRandR::Geometry'],
    predicate => 1,
);

#pod =attr Tracking
#pod
#pod An instance of L<X11::XRandR::Geometry>. Optional.
#pod
#pod =method has_Tracking
#pod
#pod I<Boolean> True if L</Tracking> was specified.
#pod
#pod =cut

has Tracking => (
    is        => 'ro',
    isa       => InstanceOf ['X11::XRandR::Geometry'],
    predicate => 1,
);

#pod =attr Transform
#pod
#pod An instance of L<X11::XRandR::Transform>.
#pod
#pod =cut

has Transform => (
    is       => 'ro',
    isa      => InstanceOf ['X11::XRandR::Transform'],
    required => 1,
);

#pod =attr primary
#pod
#pod I<Boolean>  True if the primary output.
#pod
#pod =cut

has primary => (
    is  => 'ro',
    isa => Bool
);

#pod =attr properties
#pod
#pod An array of L<X11::XRandR::Property> objects. Optional
#pod
#pod =method has_properties
#pod
#pod I<Boolean> True if L</properties> was specified.
#pod
#pod =cut

has properties => (
    is        => 'ro',
    isa       => ArrayRef [ InstanceOf['X11::XRandR::Property' ]],
    predicate => 1,
);

#pod =method to_string
#pod
#pod Return a string rendition of the object just as B<xrandr> would.
#pod
#pod =cut

sub to_string {

    my $self = shift;

    my $string
      = sprintf( "%s (0x%x) %s", $self->geometry, $self->id, $self->rotation );

    $string .= ' ' . $self->map_reflection_out( $self->reflection )
      if $self->reflection ne 'normal';

    $string;
}

my %MapReflectionIn = (
    none           => 'normal',
    'X axis'       => 'x',
    'Y axis'       => 'y',
    'X and Y axis' => 'xy',
);

my %MapReflectionOut = (
    normal => 'none',
    'x'    => 'X axis',
    'y'    => 'Y axis',
    'xy'   => 'X and Y axis',
);

#pod =method map_reflection_in
#pod
#pod Map a reflection from C<xrandr>'s nomenclature for an output to a L<X11::XRandR::Type/Reflection> value.
#pod
#pod =cut

sub map_reflection_in {
    my $self = shift;
    return $MapReflectionIn{ $_[0] };
}

#pod =method map_reflection_out
#pod
#pod Map a L<X11::XRandR::Type/Reflection> value  to  C<xrandr>'s nomenclature for an output.
#pod
#pod =cut

sub map_reflection_out {
    my $self = shift;
    return $MapReflectionOut{ $_[0] };
}

1;

#
# This file is part of X11-XRandR
#
# This software is Copyright (c) 2018 by Diab Jerius.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

__END__

=pod

=head1 NAME

X11::XRandR::Output - A video output

=head1 VERSION

version 0.01

=head1 ATTRIBUTES

=head2 name

=head2 Border

An instance of L<X11::XRandR::Border>. Optional.

=head2 Clones

Optional.

=head2 Brightness

Optional.

=head2 connection

The state of the connection.  See L<X11::XRandR::Types/Connection> for values.

=head2 CRTC

The CRTC value.

=head2 CRTCs

An array of CRTC values.

=head2 cur_crtc

An instance of L<X11::XRandR::CurCrtc>. Optional.

=head2 cur_mode

An instance of L<X11::XRandR::CurMode>. Optional.

=head2 dimension

An instance of L<X11::XRandR::Dimension>. Optional.

=head2 Gamma

An arrayref of floats. Optional.

=head2 Identifier

=head2 Timestamp

=head2 Subpixel

For values, see L<X11::XRandR::Types/SubPixelOrder>.

=head2 rotations

An array of L<X11::XRandR::Types/Direction> values

=head2 reflections

An array of C<x> and/or C<y> values.

=head2 modes

An array of L<X11::XRandR::Mode> objects.

=head2 Panning

An instance of L<X11::XRandR::Geometry>. Optional.

=head2 Tracking

An instance of L<X11::XRandR::Geometry>. Optional.

=head2 Transform

An instance of L<X11::XRandR::Transform>.

=head2 primary

I<Boolean>  True if the primary output.

=head2 properties

An array of L<X11::XRandR::Property> objects. Optional

=head1 METHODS

=head2 has_Border

I<Boolean> True if L</Border> has been specified

=head2 has_Clones

I<Boolean> True if L<Clones> was specified.

=head2 has_Brightness

I<Boolean>  True if L<Brightness> was specified.

=head2 has_cur_crtc

I<Boolean> True if L</cur_crtc> has been specified

=head2 has_cur_mode

I<Boolean> True if L</cur_mode> has been specified

=head2 has_dimension

I<Boolean>  True if L<dimension> was specified.

=head2 has_Gamma

I<Boolean>  True if L<Gamma> was specified.

=head2 has_modes

I<Boolean> True if L</modes> was specified.

=head2 has_Panning

I<Boolean> True if L</Panning> was specified.

=head2 has_Tracking

I<Boolean> True if L</Tracking> was specified.

=head2 has_properties

I<Boolean> True if L</properties> was specified.

=head2 to_string

Return a string rendition of the object just as B<xrandr> would.

=head2 map_reflection_in

Map a reflection from C<xrandr>'s nomenclature for an output to a L<X11::XRandR::Type/Reflection> value.

=head2 map_reflection_out

Map a L<X11::XRandR::Type/Reflection> value  to  C<xrandr>'s nomenclature for an output.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://rt.cpan.org/Public/Dist/Display.html?Name=X11-XRandR> or by email
to L<bug-X11-XRandR@rt.cpan.org|mailto:bug-X11-XRandR@rt.cpan.org>.

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SOURCE

The development version is on github at L<https://github.com/djerius/x11-xrandr>
and may be cloned from L<git://github.com/djerius/x11-xrandr.git>

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<X11::XRandR|X11::XRandR>

=back

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Diab Jerius.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
