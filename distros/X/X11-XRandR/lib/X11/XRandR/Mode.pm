package X11::XRandR::Mode;

# ABSTRACT: A Video Mode

use Types::Standard qw[ ArrayRef InstanceOf Bool Str ];
use Types::Common::Numeric qw[ PositiveOrZeroInt ];
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

#pod =attr current
#pod
#pod I<Boolean> is this the current mode?
#pod
#pod =cut

has current => (
    is  => 'ro',
    isa => Bool,
);

#pod =attr preferred
#pod
#pod I<Boolean> is this the preferred mode?
#pod
#pod =cut

has preferred => (
    is  => 'ro',
    isa => Bool,
);

#pod =attr modeFlags
#pod
#pod Video Mode Flags; see L<X11::XRandR::Types/ModeFlag>
#pod
#pod =cut

has modeFlags => (
    is       => 'ro',
    isa      => ArrayRef [ModeFlag],
    required => 1,
);

#pod =attr  width
#pod
#pod =attr  height
#pod
#pod =attr  hSyncStart
#pod
#pod =attr  hSyncEnd
#pod
#pod =attr  hTotal
#pod
#pod =attr  hSkew
#pod
#pod =attr  vSyncStart
#pod
#pod =attr  vSyncEnd
#pod
#pod =attr  vTotal
#pod
#pod =cut

has $_ => (
    is       => 'ro',
    isa      => PositiveOrZeroInt,
    required => 1
  )
  for qw[
  width
  height
  hSyncStart
  hSyncEnd
  hTotal
  hSkew
  vSyncStart
  vSyncEnd
  vTotal
];

#pod =attr id
#pod
#pod =cut

has id => (
    is       => 'ro',
    isa      => PositiveOrZeroInt,
    required => 1,
);

#pod =attr dotClock
#pod
#pod The refresh rate.  An instance of L<X11::XRandR::Frequency>.
#pod
#pod =cut

has dotClock => (
    is       => 'ro',
    isa      => InstanceOf ['X11::XRandR::Frequency'],
    required => 1,
);

#pod =attr hSync
#pod
#pod The horizontal sync rate.  An instance of L<X11::XRandR::Frequency>.
#pod
#pod =cut

has hSync => (
    is       => 'ro',
    isa      => InstanceOf ['X11::XRandR::Frequency'],
    required => 1,
);

#pod =attr vSync
#pod
#pod The vertical sync rate.  An instance of L<X11::XRandR::Frequency>.
#pod
#pod =cut

has vSync => (
    is       => 'ro',
    isa      => InstanceOf ['X11::XRandR::Frequency'],
    required => 1,
);

#pod =method to_string
#pod
#pod Return a string rendition of the object just as B<xrandr> would.
#pod
#pod =cut

#pod =method to_XRRModeInfo
#pod
#pod Create an XRRModeInfo object
#pod
#pod =cut

sub to_XRRModeInfo {

    require X11::XRandR::XRRModeInfo;
    my $self = shift;

    return X11::XRandR::XRRModeInfo->new(
        width    => $self->width,
        height   => $self->height,
        dotClock => $self->dotClock->to_Hz,
        hSyncStart => $self->hSyncStart,
        hSyncEnd => $self->hSyncEnd,
        hTotal => $self->hTotal,
        hSkew => $self->hSkew,
        vSyncStart => $self->vSyncStart,
        vSyncEnd => $self->vSyncEnd,
        vTotal => $self->vTotal,
    );


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

X11::XRandR::Mode - A Video Mode

=head1 VERSION

version 0.01

=head1 ATTRIBUTES

=head2 name

=head2 current

I<Boolean> is this the current mode?

=head2 preferred

I<Boolean> is this the preferred mode?

=head2 modeFlags

Video Mode Flags; see L<X11::XRandR::Types/ModeFlag>

=head2 width

=head2 height

=head2 hSyncStart

=head2 hSyncEnd

=head2 hTotal

=head2 hSkew

=head2 vSyncStart

=head2 vSyncEnd

=head2 vTotal

=head2 id

=head2 dotClock

The refresh rate.  An instance of L<X11::XRandR::Frequency>.

=head2 hSync

The horizontal sync rate.  An instance of L<X11::XRandR::Frequency>.

=head2 vSync

The vertical sync rate.  An instance of L<X11::XRandR::Frequency>.

=head1 METHODS

=head2 to_string

Return a string rendition of the object just as B<xrandr> would.

=head2 to_XRRModeInfo

Create an XRRModeInfo object

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
