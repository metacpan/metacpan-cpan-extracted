package X11::XCB::Event::ConfigureRequest;

use Mouse;

# XXX: the following are filled in by XS
has [ 'response_type', 'sequence', 'pad0', 'parent', 'stack_mode', 'window', 'sibling', 'x', 'y', 'width', 'height', 'border_width', 'value_mask' ] => (is => 'ro', isa => 'Int');

__PACKAGE__->meta->make_immutable;

1
# vim:ts=4:sw=4:expandtab
