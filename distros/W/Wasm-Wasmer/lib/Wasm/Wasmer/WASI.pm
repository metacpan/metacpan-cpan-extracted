package Wasm::Wasmer::WASI;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Wasm::Wasmer::WASI - Customized WASI configuration

=head1 SYNOPSIS

    my $wasi = $module->store()->create_wasi(
        name => 'name-of-program',  # empty string by default

        args => [ '--foo', 'bar' ],

        stdin => 'inherit',
        stdout => 'inherit',    # or 'capture'
        stderr => 'inherit',    # ^^ likewise

        env => [
            key1 => value1,
            key2 => value2,
            # ...
        ],

        preopen_dirs => [ '/path/to/dir' ],
        map_dirs => {
            '/alias/dir' => '/real/path',
            # ...
        },
    );

    my $instance = $module->create_wasi_instance($wasi);

=head1 DESCRIPTION

This module implements controls for Wasmer’s WASI implementation.
As shown above, you use it to define the imports to give to a newly-created
instance of a given module. From there you can run your program as you’d
normally do.

This module is not directly instantiated; see L<Wasm::Wasmer::Store>
for how to create an instance.

=cut

#----------------------------------------------------------------------

=head1 METHODS

=head2 $store = I<OBJ>->store()

Returns I<OBJ>’s associated L<Wasm::Wasmer::Store> instance.

=head2 $str = I<OBJ>->read_stdout($LENGTH)

Reads and returns up to $LENGTH bytes from the internal STDOUT capture.

Only useful if C<new()>’s C<stdout> was C<capture>.

=head2 $str = I<OBJ>->read_stderr($LENGTH)

Like C<read_stdout()> but for captured STDERR.

=cut

1;
