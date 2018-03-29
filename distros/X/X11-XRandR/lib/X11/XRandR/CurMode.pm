package X11::XRandR::CurMode;

# ABSTRACT: Current Mode

use Types::Standard qw[ InstanceOf ];
use Types::Common::Numeric qw[ PositiveOrZeroInt ];
use X11::XRandR::Types -types;

use Moo;
use namespace::clean;
use MooX::StrictConstructor;

our $VERSION = '0.01';

use overload '""' => \&to_string;

#pod =attr geometry
#pod
#pod An instance of L<X11::XRandR::Geometry>.
#pod
#pod =cut

has geometry => (
    is       => 'ro',
    isa      => InstanceOf ['X11::XRandR::Geometry'],
    required => 1
);

#pod =attr rotation
#pod
#pod For values, see L<X11::XRandR::Types/Direction>.
#pod
#pod =cut

has rotation => (
    is       => 'ro',
    isa      => Direction,
    required => 1,
);

#pod =attr reflection
#pod
#pod For values, see L<X11::XRandR::Types/Reflection>. Optional.
#pod
#pod =method has_reflection
#pod
#pod I<Boolean>  True if L<reflection> was specified.
#pod
#pod =cut

has reflection => (
    is        => 'ro',
    isa       => Reflection,
    predicate => 1,
);

#pod =attr id
#pod
#pod =cut

has id => (
    is  => 'ro',
    isa => PositiveOrZeroInt
);

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
    normal         => 'none',
    'x'            => 'X axis',
    'y'            => 'Y axis',
    'xy'           => 'X and Y axis',
);

#pod =method map_reflection_in
#pod
#pod Map a reflection from C<xrandr>'s nomenclature for the current mode to a L<X11::XRandR::Type/Reflection> value.
#pod
#pod =cut

sub map_reflection_in {
    my $self = shift;
    return $MapReflectionIn{ $_[0] };
}

#pod =method map_reflection_out
#pod
#pod Map a L<X11::XRandR::Type/Reflection> value to C<xrandr>'s nomenclature for the current mode.
#pod
#pod =cut

sub map_reflection_out {
    my $self = shift;
    return $MapReflectionOut{ $_[0] };
}

#pod =method to_string
#pod
#pod Return a string rendition of the object just as B<xrandr> would.
#pod
#pod =cut

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

X11::XRandR::CurMode - Current Mode

=head1 VERSION

version 0.01

=head1 ATTRIBUTES

=head2 geometry

An instance of L<X11::XRandR::Geometry>.

=head2 rotation

For values, see L<X11::XRandR::Types/Direction>.

=head2 reflection

For values, see L<X11::XRandR::Types/Reflection>. Optional.

=head2 id

=head1 METHODS

=head2 has_reflection

I<Boolean>  True if L<reflection> was specified.

=head2 map_reflection_in

Map a reflection from C<xrandr>'s nomenclature for the current mode to a L<X11::XRandR::Type/Reflection> value.

=head2 map_reflection_out

Map a L<X11::XRandR::Type/Reflection> value to C<xrandr>'s nomenclature for the current mode.

=head2 to_string

Return a string rendition of the object just as B<xrandr> would.

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
