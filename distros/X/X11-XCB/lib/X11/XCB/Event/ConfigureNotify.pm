package X11::XCB::Event::ConfigureNotify;

use Mouse;

# XXX: the following are filled in by XS
has [ 'response_type', 'sequence', 'pad0', 'event', 'window', 'above_sibling', 'x', 'y', 'width', 'height', 'border_width', 'override_redirect' ] => (is => 'ro', isa => 'Int');

__PACKAGE__->meta->make_immutable;

1
# vim:ts=4:sw=4:expandtab
