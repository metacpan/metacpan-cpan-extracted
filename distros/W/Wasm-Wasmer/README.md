# NAME

Wasm::Wasmer - [WebAssembly](https://webassembly.org) in Perl via
[Wasmer](https://wasmer.io)

# SYNOPSIS

    use Wasm::Wasmer;

    my $wasm = Wasm::Wasmer::wat2wasm( <<END );
    (module
        (type (func (param i32 i32) (result i32)))
        (func $add (type 0)
            local.get 0
            local.get 1
            i32.add)
        (export "sum" (func $add))
    )
    END

    my $instance = Wasm::Wasmer::Module->new($wasm)->create_instance();

    # Prints 7:
    print $instance->call('sum', 2, 5) . $/;

# DESCRIPTION

This distribution provides an XS binding for Wasmer.
This provides a simple, fast way to run WebAssembly (WASM) in Perl.

# MODULE RELATIONSHIPS

We mostly follow the relationships from
[Wasmer’s C API](https://docs.rs/wasmer-c-api):

- [Wasm::Wasmer::Store](https://metacpan.org/pod/Wasm%3A%3AWasmer%3A%3AStore) manages Wasmer’s state, including
storage of any imports & exports. It contains compiler & engine
configuration as well. This object can be auto-created by default
or manually instantiated.
- [Wasm::Wasmer::Module](https://metacpan.org/pod/Wasm%3A%3AWasmer%3A%3AModule) uses a [Wasm::Wasmer::Store](https://metacpan.org/pod/Wasm%3A%3AWasmer%3A%3AStore) instance
to represent a parsed WASM module. This one you always instantiate
manually.
- [Wasm::Wasmer::Instance](https://metacpan.org/pod/Wasm%3A%3AWasmer%3A%3AInstance) uses a [Wasm::Wasmer::Module](https://metacpan.org/pod/Wasm%3A%3AWasmer%3A%3AModule) instance
to represent an in-progress WASM program. You’ll instantiate these
via methods on the [Wasm::Wasmer::Module](https://metacpan.org/pod/Wasm%3A%3AWasmer%3A%3AModule) object.

# CHARACTER ENCODING

Generally speaking, strings that in common usage are human-readable
(e.g., names of imports & exports) are character strings. Ensure
that you’ve properly character-decoded such strings, or any non-ASCII
characters will cause encoding bugs.

(TIP: Always incorporate code points 128-255 into your testing.)

Binary payloads (e.g., memory contents) are byte strings.

# PLATFORM SUPPORT

As of this writing, Wasmer’s platform support constrains this module
to supporting Linux and macOS only. (Windows might also work?)

# SEE ALSO

[Wasm::Wasmtime](https://metacpan.org/pod/Wasm%3A%3AWasmtime) is an FFI binding to
[https://wasmtime.dev](https://wasmtime.dev), a similar project to Wasmer.

[Wasm](https://metacpan.org/pod/Wasm) provides syntactic sugar around Wasm::Wasmtime.

# FUNCTIONS

This namespace defines the following:

## $bin = wat2wasm( $TEXT )

Converts WASM text format to its binary-format equivalent. $TEXT
should be (character-decoded) text.

# LICENSE & COPYRIGHT

Copyright 2022 Gasper Software Consulting. All rights reserved.

This library is licensed under the same terms as Perl itself.
See [perlartistic](https://metacpan.org/pod/perlartistic).

This library was originally a research project at
[cPanel, L.L.C.](https://cpanel.net).
