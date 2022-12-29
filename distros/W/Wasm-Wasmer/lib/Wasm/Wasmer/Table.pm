package Wasm::Wasmer::Table;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Wasm::Wasmer::Table - WebAssembly table

=head1 SYNOPSIS

    my $table = $instance->export('some_named_table');

    printf "Table size: %d\n", $table->size();

=head1 DESCRIPTION

This class represents external WebAssembly tables. It subclasses
L<Wasm::Wasmer::Extern>.

It’s limited by Wasmer’s own external table support, which currently
allows only trivial interactions. Once Wasmer’s table support improves,
this library can as well.

=cut

#----------------------------------------------------------------------

use parent 'Wasm::Wasmer::Extern';

#----------------------------------------------------------------------

=head1 METHODS

=head2 $size = I<OBJ>->size()

Returns the number of elements in the table.

=cut

1;
