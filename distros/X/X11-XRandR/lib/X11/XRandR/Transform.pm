package X11::XRandR::Transform;

# ABSTRACT: A transform

use Types::Common::Numeric qw[ PositiveOrZeroInt ];
use Types::Standard qw[ Undef ];
use X11::XRandR::Types -types;

use Moo;
use namespace::clean;
use MooX::StrictConstructor;

our $VERSION = '0.01';

#pod =attr filter
#pod
#pod See L<X11::XRandR::Types/Filter> for values.  Optional
#pod
#pod =method has_filter
#pod
#pod I<Boolean>  True if L<filter> was specified.
#pod
#pod =cut

has filter => (
    is        => 'ro',
    isa       => Filter | Undef,
    predicate => 1,
    clearer   => 1,
);

#pod =attr matrix
#pod
#pod A transformation matrix.  See L<X11::XRandR::Types/XTransform>.
#pod
#pod =cut

has matrix => (
    is      => 'ro',
    isa     => XTransform,
    default => sub {
        [ [ 1, 0, 0 ],
          [ 0, 1, 0 ],
          [ 0, 0, 1 ],
        ];
    },
);


#pod =for Pod::Coverage BUILD
#pod
#pod =cut

sub BUILD {

    my $self = shift;
    $self->clear_filter if !defined $self->filter;
}

#pod =method to_string
#pod
#pod Return a string rendition of the object just as B<xrandr> would.
#pod
#pod =cut

sub to_string {
    sprintf( "%d/%d/%d/%d",
        $_[0]->left, $_[0]->top, $_[0]->right, $_[1]->bottom );
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

X11::XRandR::Transform - A transform

=head1 VERSION

version 0.01

=head1 ATTRIBUTES

=head2 filter

See L<X11::XRandR::Types/Filter> for values.  Optional

=head2 matrix

A transformation matrix.  See L<X11::XRandR::Types/XTransform>.

=head1 METHODS

=head2 has_filter

I<Boolean>  True if L<filter> was specified.

=head2 to_string

Return a string rendition of the object just as B<xrandr> would.

=for Pod::Coverage BUILD

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
