package X11::XRandR::Geometry;

# ABSTRACT: A Screen or output geometry

use Types::Standard qw[ InstanceOf ];

use X11::XRandR::Dimension;
use X11::XRandR::Offset;

use Moo;
use namespace::clean;
use MooX::StrictConstructor;

our $VERSION = '0.01';

use overload '""' => \&to_string;

#pod =attr dimension
#pod
#pod An instance of L<X11::XRandR::Dimension>.
#pod
#pod =cut


has dimension => (
    is       => 'rw',
    isa      => InstanceOf ['X11::XRandR::Dimension'],
    required => 1,
);

#pod =attr dimension
#pod
#pod An instance of L<X11::XRandR::Offset>.
#pod
#pod =cut

has offset => (
    is      => 'rw',
    isa     => InstanceOf ['X11::XRandR::Offset'],
    default => sub { X11::XRandR::Offset->new },
);

#pod =method to_string
#pod
#pod Return a string rendition of the object just as B<xrandr> would.
#pod
#pod =cut

sub to_string {
    $_[0]->dimension->to_string . $_[0]->offset->to_string;
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

X11::XRandR::Geometry - A Screen or output geometry

=head1 VERSION

version 0.01

=head1 ATTRIBUTES

=head2 dimension

An instance of L<X11::XRandR::Dimension>.

=head2 dimension

An instance of L<X11::XRandR::Offset>.

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
