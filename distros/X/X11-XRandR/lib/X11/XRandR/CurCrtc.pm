package X11::XRandR::CurCrtc;

# ABSTRACT: Current CRTC

use Types::Standard qw[ InstanceOf ];
use Types::Common::Numeric qw[ PositiveOrZeroInt ];
use X11::XRandR::Types -types;

use Moo;
use namespace::clean;
use MooX::StrictConstructor;

our $VERSION = '0.01';

use overload '""' => \&to_string;

#pod =attr panning
#pod
#pod An instance of L<X11::XRandR::Geometry>. Optional.
#pod
#pod =method has_panning
#pod
#pod I<Boolean>  True if L<panning> was specified.
#pod
#pod =cut

has panning => (
    is       => 'ro',
    isa      => InstanceOf ['X11::XRandR::Geometry'],
                predicate => 1
);

#pod =attr tracking
#pod
#pod An instance of L<X11::XRandR::Geometry>. Optional.
#pod
#pod =method has_tracking
#pod
#pod I<Boolean>  True if L<tracking> was specified.
#pod
#pod =cut

has tracking => (
    is       => 'ro',
    isa      => InstanceOf ['X11::XRandR::Geometry'],
                predicate => 1
);

#pod =attr border
#pod
#pod An instance of L<X11::XRandR::Border>. Optional.
#pod
#pod =method has_border
#pod
#pod I<Boolean>  True if L<border> was specified.
#pod
#pod =cut

has border => (
    is       => 'ro',
    isa      => InstanceOf ['X11::XRandR::Border'],
                predicate => 1
);

#pod =method to_string
#pod
#pod Return a string rendition of the object just as B<xrandr> would.
#pod
#pod =cut

sub to_string {

    my $self = shift;

    my @text;
    push @text, sprintf( "panning %s", $self->panning->to_string ) if $self->have_panning;
    push @text, sprintf( "tracking %s", $self->tracking->to_string ) if $self->have_tracking;
    push @text, sprintf( "tracking %s", $self->tracking->to_string ) if $self->have_tracking;

    return join( ' ', @text );
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

X11::XRandR::CurCrtc - Current CRTC

=head1 VERSION

version 0.01

=head1 ATTRIBUTES

=head2 panning

An instance of L<X11::XRandR::Geometry>. Optional.

=head2 tracking

An instance of L<X11::XRandR::Geometry>. Optional.

=head2 border

An instance of L<X11::XRandR::Border>. Optional.

=head1 METHODS

=head2 has_panning

I<Boolean>  True if L<panning> was specified.

=head2 has_tracking

I<Boolean>  True if L<tracking> was specified.

=head2 has_border

I<Boolean>  True if L<border> was specified.

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
