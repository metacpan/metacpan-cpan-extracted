package X11::XCB::Event::PropertyNotify;

use Mouse;

# XXX: the following are filled in by XS
has [ 'response_type', 'sequence', 'pad0', 'window', 'atom', 'time', 'state' ] => (is => 'ro', isa => 'Int');

__PACKAGE__->meta->make_immutable;

1
# vim:ts=4:sw=4:expandtab
