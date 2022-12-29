package Wasm::Wasmer::Function;

use strict;
use warnings;

use parent 'Wasm::Wasmer::Extern';

=encoding utf-8

=head1 NAME

Wasm::Wasmer::Function - WebAssembly function

=head1 SYNOPSIS

    my $module = Wasm::Wasmer::Module->new($wasm_bin);

    my $func = $module->create_instance()->export('somefunc');

    my @got = $func->call(2, 34);

=head1 DESCRIPTION

This class represents a WebAssembly function: either an exported one or
a Perl callback to give to WebAssembly. It is not instantiated directly.

This class subclasses L<Wasm::Wasmer::Extern>.

=head1 METHODS

=head2 @RETURNS = I<OBJ>->call(@INPUTS)

Calls the function, passing the
given @INPUTS and returning the returned values as a list.

@INPUTS B<must> match the function’s export signature in both type and
length; e.g., if a function expects (i32, f64) and you pass (4.3, 12),
or give too many or too few parameters, an exception will be thrown
that explains the discrepancy.

If the function returns multiple items, scalar context is forbidden.
(Void context is always allowed, though.)

=head3 Notes

=over

=item * If I<OBJ> is an export from a WASI-enabled WASM instance
then the WASI start function will run automatically if needed prior to
running I<OBJ>.

=back

=cut

1;
