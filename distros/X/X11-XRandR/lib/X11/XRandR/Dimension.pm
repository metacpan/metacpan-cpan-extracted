package X11::XRandR::Dimension;

# ABSTRACT: Dimension of Screen or Display

use Types::Standard qw[ Enum ];
use Types::Common::Numeric qw[ PositiveOrZeroInt ];

use Moo;
use namespace::clean;
use MooX::StrictConstructor;

our $VERSION = '0.01';

#pod =attr x
#pod
#pod =attr y
#pod
#pod A dimension.
#pod
#pod =cut

use overload '""' => \&to_string;
has $_            => (
    is       => 'ro',
    isa      => PositiveOrZeroInt,
    required => 1,
) for qw[ x y ];

#pod =attr unit
#pod
#pod Units; either C<pixel> or C<mm>
#pod
#pod =cut

has unit => (
             is => 'ro',
             isa => Enum[ qw[ pixel mm ] ],
             default => 'pixel',
            );

#pod =method to_string
#pod
#pod Return a string rendition of the object just as B<xrandr> would.
#pod
#pod =cut

sub to_string {
    sprintf( "%dx%d", $_[0]->x, $_[0]->y );
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

X11::XRandR::Dimension - Dimension of Screen or Display

=head1 VERSION

version 0.01

=head1 ATTRIBUTES

=head2 x

=head2 y

A dimension.

=head2 unit

Units; either C<pixel> or C<mm>

=head1 METHODS

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
