package Wasm::Wasmer::Global;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Wasm::Wasmer::Global - WebAssembly global

=head1 SYNOPSIS

    my $store = Wasm::Wasmer::Store->new();

    my $life = $store->create_i32_const(42);

=head1 DESCRIPTION

This class represents WebAssembly global imports & exports.

This class subclasses L<Wasm::Wasmer::Extern>.

=cut

#----------------------------------------------------------------------

use parent 'Wasm::Wasmer::Extern';

#----------------------------------------------------------------------

=head1 METHODS

=head2 $val = I<OBJ>->get()

Retrieves the global’s current value.

=head2 $obj = I<OBJ>->set( $NEW_VALUE )

Sets the global’s value. If called on a constant/non-mutable global
this throws.

=head2 $mut = I<OBJ>->mutability()

Returns a number that represents the object’s mutability state.
The constants C<Wasm::Wasmer::WASM_VAR> and C<Wasm::Wasmer::WASM_CONST>
indicate mutability and non-mutability, respectively.

(You I<can> currently treat C<$mut> as a boolean, and that will I<probably>
never bite you. But that’s not 100% certain.)

=cut

1;
