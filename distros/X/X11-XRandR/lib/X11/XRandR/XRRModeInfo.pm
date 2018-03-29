package X11::XRandR::XRRModeInfo;

# ABSTRACT: Mirror of X11 XRRModeInfo structure

use Types::Standard -types;
use Types::Common::Numeric -types;
use X11::XRandR::Types -types;


use Moo;
use namespace::clean;
use MooX::StrictConstructor;

our $VERSION = '0.01';

#pod =attr id
#pod
#pod =cut

has id => (
    is       => 'ro',
    isa      => XID,
    required => 1,
);

#pod =attr  width
#pod
#pod =attr  height
#pod
#pod =attr  dotClock
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
  dotClock
  hSyncStart
  hSyncEnd
  hTotal
  hSkew
  vSyncStart
  vSyncEnd
  vTotal
];

#pod =attr name
#pod
#pod =cut

has name => ( is => 'ro', isa => Str );

#pod =attr modeFlags
#pod
#pod Video Mode Flags; see L<X11::XRandR::Types/ModeFlag>
#pod
#pod =cut

has modeFlags => (
    is  => 'ro',
    isa => ArrayRef [ModeFlag],
);

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

X11::XRandR::XRRModeInfo - Mirror of X11 XRRModeInfo structure

=head1 VERSION

version 0.01

=head1 ATTRIBUTES

=head2 id

=head2 width

=head2 height

=head2 dotClock

=head2 hSyncStart

=head2 hSyncEnd

=head2 hTotal

=head2 hSkew

=head2 vSyncStart

=head2 vSyncEnd

=head2 vTotal

=head2 name

=head2 modeFlags

Video Mode Flags; see L<X11::XRandR::Types/ModeFlag>

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
