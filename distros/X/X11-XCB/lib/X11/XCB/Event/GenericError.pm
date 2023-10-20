package X11::XCB::Event::GenericError;

use Mouse;

# XXX: the following are filled in by XS
has [ 'response_type', 'sequence', 'pad0', 'error_code', 'sequence', 'resource_id', 'minor_code', 'major_code' ] => (is => 'ro', isa => 'Int');

__PACKAGE__->meta->make_immutable;

1
# vim:ts=4:sw=4:expandtab
