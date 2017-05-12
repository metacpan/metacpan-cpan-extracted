package X11::XCB::Screen;

use Mouse;
use X11::XCB::Rect;

has 'rect' => (is => 'ro', isa => 'X11::XCB::Rect', required => 1);

=head1 NAME

X11::XCB::Screen - represents an x11 screen

=head1 METHODS

=head2 primary

Returns true if this screen is the primary screen (that is, at position 0x0).

=cut
sub primary {
    my $self = shift;

    return ($self->rect->x == 0 && $self->rect->y == 0);
}

1
# vim:ts=4:sw=4:expandtab
