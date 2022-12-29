package Wasm::Wasmer::Memory;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Wasm::Wasmer::Memory - WebAssembly memory

=head1 SYNOPSIS

    my $store = Wasm::Wasmer::Store->new();

    my $life = $store->create_memory( initial => 2 );

=head1 DESCRIPTION

This class represents WebAssembly memory imports & exports.

This class subclasses L<Wasm::Wasmer::Extern>.

=cut

#----------------------------------------------------------------------

use parent 'Wasm::Wasmer::Extern';

#----------------------------------------------------------------------

=head1 CONSTANTS

=head2 C<PAGE_SIZE>

The size, in bytes, of each page.

=head1 METHODS

=head2 $bytes = I<OBJ>->get( [ $OFFSET [, $LENGTH ] ] )

Retrieves the memory’s contents as a byte string.

$OFFSET and $LENGTH behave as they do with L<perlfunc/substr>,
but negative $LENGTH is currently unsupported.

To retrieve the entire buffer:

    $memory->get()

To retrieve the entire buffer except the first 9 bytes:

    $memory->get(9)

To retrieve a 5-byte string starting at offset 8:

    $memory->get(8, 5);

=head2 $obj = I<OBJ>->set( $NEW_BYTES [, $OFFSET] )

Splices a new byte sequence into the memory, starting at $OFFSET (0 by
default). Returns I<OBJ>.

Throws if there’s a range error or if $NEW_BYTES contains any >255
code points.

=head2 $obj = I<OBJ>->grow( $DELTA )

Grows the memory by $DELTA (nonnegative) pages, or throws an error
if that grow operation fails. Returns I<OBJ>.

=head2 ($initial, $maximum) = I<OBJ>->limits()

Returns the memory’s lower & upper page-count limits.

=head2 $pages = I<OBJ>->size()

Returns the memory’s current size in pages.
(The byte length is C<$pages * Wasm::Wasmer::PAGE_SIZE>.)

=cut

use Wasm::Wasmer;

1;
