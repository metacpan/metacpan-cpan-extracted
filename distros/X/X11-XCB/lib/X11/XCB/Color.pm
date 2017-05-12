package X11::XCB::Color;

use Mouse;
use Mouse::Util::TypeConstraints;

coerce 'X11::XCB::Color'
    => from 'Str'
    => via { X11::XCB::Color->new(hexcode => $_) };

has 'hexcode' => (is => 'ro', isa => 'Str', required => 1);
has 'pixel' => (is => 'ro', isa => 'Int', lazy_build => 1);
has '_conn' => (is => 'ro');
# FIXME: We need the X connection as soon as we implement more than a
# truecolor. However, I don’t have an idea for getting the coercion to
# work then.
#, required => 1);

=head1 NAME

X11::XCB::Color - X11 colorpixel handling

=head1 METHODS

=head2 pixel

Returns the colorpixel (think of an ID) of this color. Works with TrueColor
displays only at the moment.

=cut
sub _build_pixel {
    my $self = shift;
    my $hex = $self->hexcode;

    # Strip optional leading # from hex code
    $hex =~ s/^#//;

    return hex($hex);
}

1
# vim:ts=4:sw=4:expandtab
