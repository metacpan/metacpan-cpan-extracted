package X11::XRandR::Types;

# ABSTRACT: Types

use strict;
use warnings;

use Type::Utils -all;
use Types::Standard -types;
use Types::Common::Numeric qw[ PositiveOrZeroInt ];

our $VERSION = '0.01';

use Type::Library
  -base,
  -declare => qw(
  Filter
  Capability
  Connection
  Direction
  Reflection
  Relation
  SubPixelOrder
  ModeFlag
  XFixed
  XTransform
  XID
);

#pod =type Filter
#pod
#pod C<bilinear>, C<nearest>.
#pod
#pod =cut

declare Filter,
  as Enum [qw( bilinear nearest )];

#pod =type Direction
#pod
#pod C<normal>, C<left>, C<inverted>, C<right>.
#pod
#pod =cut

declare Direction, as Enum [qw( normal left inverted right )];

#pod =type Reflection
#pod
#pod C<normal>, C<x>, C<y>, C<xy>.
#pod
#pod =cut

declare Reflection, as Enum [qw( normal x y xy )];

#pod =type SubPixelOrder
#pod
#pod One of C<unknown>, C<horizontal rgb>, C<horizontal bgr>, C<vertical rgb>, C<vertical bgr>, C<no subpixels>.
#pod
#pod =cut

declare SubPixelOrder,
  as Enum [
    "unknown",
    "horizontal rgb",
    "horizontal bgr",
    "vertical rgb",
    "vertical bgr",
    "no subpixels",
  ];

#pod =type ModeFlag
#pod
#pod Video Mode Flags:
#pod
#pod C<+HSync>, C<-HSync>, C<+VSync>, C<-VSync>, C<Interlace>, C<DoubleScan>, C<CSync>,  C<+CSync>, C<-CSync>,
#pod
#pod =cut

declare ModeFlag,
  as Enum [
    "+HSync",    "-HSync",     "+VSync", "-VSync",
    "Interlace", "DoubleScan", "CSync",  "+CSync",
    "-CSync",
  ];

#pod =attr Capability
#pod
#pod C<Source Output>, C<Sink Output>, C<Source Offload>, C<Sink Offload>
#pod
#pod =cut

declare Capability,
  as Enum [ "Source Output", "Sink Output", "Source Offload", "Sink Offload", ];

#pod =type Connection
#pod
#pod One of C<connected>, C<disconnected>, C<unknown connection>.
#pod
#pod =cut

declare Connection,
  as Enum [ "connected", "disconnected", "unknown connection" ];

declare Relation, as Enum [qw( left_of right_of above below same_as )];

#pod =type XTransform
#pod
#pod A transformation matrix.  Nested arrays:
#pod
#pod   [
#pod     [ Num, Num, Num ],
#pod     [ Num, Num, Num ],
#pod     [ Num, Num, Num ],
#pod   ];
#pod
#pod =cut

declare XTransform,
  as Tuple[
    Tuple[ Num, Num, Num ],
    Tuple[ Num, Num, Num ],
    Tuple[ Num, Num, Num ],
  ];

1;

#pod =type XID
#pod
#pod =cut

declare XID, as PositiveOrZeroInt;


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

X11::XRandR::Types - Types

=head1 VERSION

version 0.01

=head1 ATTRIBUTES

=head2 Capability

C<Source Output>, C<Sink Output>, C<Source Offload>, C<Sink Offload>

=head1 TYPES

=head2 Filter

C<bilinear>, C<nearest>.

=head2 Direction

C<normal>, C<left>, C<inverted>, C<right>.

=head2 Reflection

C<normal>, C<x>, C<y>, C<xy>.

=head2 SubPixelOrder

One of C<unknown>, C<horizontal rgb>, C<horizontal bgr>, C<vertical rgb>, C<vertical bgr>, C<no subpixels>.

=head2 ModeFlag

Video Mode Flags:

C<+HSync>, C<-HSync>, C<+VSync>, C<-VSync>, C<Interlace>, C<DoubleScan>, C<CSync>,  C<+CSync>, C<-CSync>,

=head2 Connection

One of C<connected>, C<disconnected>, C<unknown connection>.

=head2 XTransform

A transformation matrix.  Nested arrays:

  [
    [ Num, Num, Num ],
    [ Num, Num, Num ],
    [ Num, Num, Num ],
  ];

=head2 XID

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
