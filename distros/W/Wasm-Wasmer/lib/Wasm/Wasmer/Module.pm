package Wasm::Wasmer::Module;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Wasm::Wasmer::Module

=head1 SYNOPSIS

    my $module = Wasm::Wasmer::Module->new( $wasm_bin );

… or, to use a pre-built L<Wasm::Wasmer::Store> instance:

    my $module = Wasm::Wasmer::Module->new( $wasm_bin, $store );

… then:

    my $instance = $module->create_instance();

… or, for L<WASI|http://wasi.dev>:

    my $wasi = $module->store()->create_wasi( .. );

    my $instance = $module->create_wasi_instance($wasi);

You can also specify imports; see below.

=head1 DESCRIPTION

This class represents a parsed WebAssembly module.

See L<Wasmer’s documentation|https://docs.rs/wasmer-c-api/2.0.0/wasmer_c_api/wasm_c_api/module> for a bit more context.

=head1 METHODS

=head2 $obj = I<CLASS>->new( $WASM_BIN [, $STORE ] )

Parses a WebAssembly module in binary (C<.wasm>) format
and returns a I<CLASS> instance representing that.

(To use text/C<.wat> format instead, see L<Wasm::Wasmer>’s C<wat2wasm()>.)

Optionally associates the parse of that module with a
L<Wasm::Wasmer::Store> instance.

=head2 $instance = I<OBJ>->create_instance( [ \%IMPORTS ] )

Creates a L<Wasm::Wasmer::Instance> instance from I<OBJ> with the
(optional) given %IMPORTS. (NB: %IMPORTS is given via I<reference>.)

%IMPORTS is an optional hash-of-hashrefs that describes the set of
imports to give to the new instance.

Here’s a simple example that gives a function C<ns>.C<give2> to WebAssembly
that just returns the number 2:

    my $instance = $module->create_instance(
        {
            ns => {
                give2 => sub { 2 },
            },
        },
    );

Other import types are rather more complex because they’re interactive;
thus, you have to create them prior to calling C<create_instance()> and
include your import objects in %IMPORTS.

    my $const = $module->store()->create_i32_const( 42 );
    my $var   = $module->store()->create_f64_mut( 2.718281828 );

    my $memory = $module->store()->create_memory( initial => 3 );

(Tables are currently unsupported.)

So, if we alter our above example to import our constants and memory
as well as the function, we have:

    my $instance = $module->create_instance(
        {
            ns => {
                give2 => sub { 2 },

                # These values are all pre-created objects:
                constvar => $const,
                mutvar   => $mut,
                memory   => $memory,
            },
        },
    );

NB: Instances can share imports, even if they’re instances of different
WASM modules.

=head2 $instance = I<OBJ>->create_wasi_instance( $WASI, [ \%IMPORTS ] )

Creates a L<Wasm::Wasmer::Instance> instance from I<OBJ>.
That object’s WebAssembly imports will include the L<WASI|https://wasi.dev>
interface.

$WASI argument is either undef or a L<Wasm::Wasmer::WASI> instance.
Undef is equivalent to C<$self-E<gt>store()-E<gt>create_wasi()>.

The optional %IMPORTS reference (I<reference>!) is as for C<create_instance()>.
Note that you can override WASI imports with this, if you so desire.

=head2 $global = I<OBJ>->create_global( $VALUE )

Creates a L<Wasm::Wasmer::Import::Global> instance. See that module’s
documentation for more details.

=head2 $global = I<OBJ>->create_memory()

Creates a L<Wasm::Wasmer::Import::Memory> instance. See that module’s
documentation for more details. Currently this accepts no parameters;
instead it conforms to the WASM module’s needs.

=head2 $bytes = I<OBJ>->serialize()

Serializes the in-memory module for later use. (cf. C<deserialize()> below)

=cut

=head2 $store = I<OBJ>->store()

Returns I<OBJ>’s underlying L<Wasm::Wasmer::Store> instance.

=head1 STATIC FUNCTIONS

=head2 $module = deserialize( $SERIALIZED_BIN [, $STORE ] )

Like this class’s C<new()> method but takes a serialized module
rather than WASM code.

=head2 $yn = validate( $WASM_BIN [, $STORE ] )

Like this class’s C<new()> but just returns a boolean to indicate whether
$WASM_BIN represents a valid module.

=cut

use Wasm::Wasmer;

1;
