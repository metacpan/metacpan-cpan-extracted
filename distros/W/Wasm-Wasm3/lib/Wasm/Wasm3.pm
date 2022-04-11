package Wasm::Wasm3;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Wasm::Wasm3 - Self-contained L<WebAssembly|https://webassembly.org/> via L<wasm3|https://github.com/wasm3/wasm3>

=head1 SYNOPSIS

Basic setup:

    my $env = Wasm::Wasm3->new();
    my $module = $env->parse_module($wasm_binary);
    my $runtime = $env->create_runtime(1024)->load_module($module);

WebAssembly-exported globals:

    my $global = $module->get_global('some-value');

    $module->set_global('some-value', 1234);

WebAssembly-exported memory:

    $runtime->set_memory( $offset, $bytes );

    my $from_wasm = $runtime->get_memory( $offset, $length );

Call a WebAssembly-exported function:

    my @out = $runtime->call('some-func', @args);

Implement a WebAssembly-imported function in Perl:

    $runtime->link_function('mod-name', 'func-name', 'v(ii)', $coderef);

(C<v(ii)> is the function’s signature; see L<Wasm::Wasm3::Runtime> for
details.)

=head1 DESCRIPTION

Well-known WebAssembly runtimes like L<Wasmer|https://wasmer.io>,
L<Wasmtime|https://wasmtime.dev>, or L<WAVM|https://github.com/wavm/wavm>
often require nonstandard dependencies/toolchains (e.g., LLVM or Rust).
Their builds can take a while, especially on slow machines, and only
the most popular platforms may enjoy support.

L<wasm3|https://github.com/wasm3/wasm3> takes a different tactic from
the aforementioned “big dogs”: whereas those are all JIT compilers,
wasm3 is a WebAssembly I<interpreter>. This makes it quite small and
fast/simple to build, which lets you run WebAssembly in environments
that something bigger may not support. Runtime performance lags the
“big dogs” significantly, but startup latency will likely be lower, and
memory usage is B<much> lower.

This distribution includes wasm3, so you don’t need to build it yourself.

=head1 STATUS

This Perl library is EXPERIMENTAL.

Additionally, wasm3 is, as of this writing, rather less complete than
Wasmer et al. wasm3 only exports a single WebAssembly memory, for
example. It can’t import memories or globals, and it neither imports
I<nor> exports tables.

=head1 DOCUMENTATION

This module generally documents only those aspects of its usage that
are germane to this module specifically. For more details, see
wasm3’s documentation.

=cut

#----------------------------------------------------------------------

use XSLoader;

our $VERSION;

BEGIN {
    $VERSION = '0.01';

    XSLoader::load( __PACKAGE__, $VERSION );
}

use constant M3_VERSION => (_M3_VERSION_MAJOR, _M3_VERSION_MINOR, _M3_VERSION_REV);

#----------------------------------------------------------------------

=head1 STATIC FUNCTIONS & CONSTANTS

=head2 ($MAJOR, $MINOR, $REV) = M3_VERSION

Returns wasm3’s version as 3 integers.

=head2 $STRING = M3_VERSION_STRING

Returns wasm3’s version as a string.

=head2 C<TYPE_I32>, C<TYPE_I64>, C<TYPE_F32>, C<TYPE_F64>

Numeric constants that indicate the corresponding WebAssembly type.

=head1 METHODS

=head2 $OBJ = I<CLASS>->new()

Instantiates I<CLASS>.
Creates a new wasm3 environment and binds it to the returned object.

=head2 $RUNTIME = I<OBJ>->create_runtime( $STACKSIZE )

Creates a new wasm3 runtime from I<OBJ>.
Returns a L<Wasm::Wasm3::Runtime> instance.

=head2 $MODULE = I<OBJ>->parse_module( $WASM_BINARY )

Loads a WebAssembly module from I<binary> (F<*.wasm>) format.
Returns a L<Wasm::Wasm3::Module> instance.

If your WebAssembly module is in text format rather than binary,
you’ll need to convert it first. Try
L<wabt|https://github.com/webassembly/wabt> if you need such a tool.

=cut

=head1 LICENSE & COPYRIGHT

Copyright 2022 Gasper Software Consulting. All rights reserved.

This library is licensed under the same terms as Perl itself.
See L<perlartistic>.

=cut

1;
