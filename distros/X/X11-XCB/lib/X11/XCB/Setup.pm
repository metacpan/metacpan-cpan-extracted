package X11::XCB::Setup;

use Mouse;

# XXX: the following are filled in by XS
has [ 'status', 'protocol_major_version', 'protocol_minor_version', 'length', 'release_number', 'resource_id_base', 'resource_id_mask', 'motion_buffer_size', 'vendor_len', 'maximum_request_length', 'roots_len', 'pixmap_formats_len', 'image_byte_order', 'bitmap_format_bit_order', 'bitmap_format_scanline_unit', 'bitmap_format_scanline_pad', 'min_keycode', 'max_keycode' ] => (is => 'ro', isa => 'Int');

__PACKAGE__->meta->make_immutable;

1
# vim:ts=4:sw=4:expandtab
