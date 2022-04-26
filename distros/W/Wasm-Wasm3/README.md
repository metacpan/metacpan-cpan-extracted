# NAME

Wasm::Wasm3 - Self-contained [WebAssembly](https://webassembly.org/) via [wasm3](https://github.com/wasm3/wasm3)

# SYNOPSIS

Basic setup:

    my $env = Wasm::Wasm3->new();
    my $module = $env->parse_module($wasm_binary);
    my $runtime = $env->create_runtime(1024)->load_module($module);

Run [WASI](https://wasi.dev):

    my $exit_code = $runtime->run_wasi('arg1', 'arg2');

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

(`v(ii)` is the function’s signature; see [Wasm::Wasm3::Runtime](https://metacpan.org/pod/Wasm%3A%3AWasm3%3A%3ARuntime) for
details.)

# DESCRIPTION

Well-known WebAssembly runtimes like [Wasmer](https://wasmer.io),
[Wasmtime](https://wasmtime.dev), or [WAVM](https://github.com/wavm/wavm)
often require nonstandard dependencies/toolchains (e.g., LLVM or Rust).
Their builds can take a while, especially on slow machines, and only
the most popular platforms may enjoy support.

[wasm3](https://github.com/wasm3/wasm3) takes a different tactic from
the aforementioned “big dogs”: whereas those are all JIT compilers,
wasm3 is a WebAssembly _interpreter_. This makes it quite small and
fast/simple to build, which lets you run WebAssembly in environments
that something bigger may not support. Runtime performance lags the
“big dogs” significantly, but startup latency will likely be lower, and
memory usage is **much** lower.

This distribution includes wasm3, so you don’t need to build it yourself.

# STATUS

This Perl library is EXPERIMENTAL.

Additionally, wasm3 is, as of this writing, rather less complete than
Wasmer et al. wasm3 only exports a single WebAssembly memory, for
example. It can’t import memories or globals, and it neither imports
_nor_ exports tables.

# [WASI](https://wasi.dev) SUPPORT

wasm3 implements WASI via either of (as of this writing) two backends:
a wrapper around [uvwasi](https://github.com/nodejs/uvwasi), and a
less-complete original implementation. The former needs
[libuv](https://libuv.org), which doesn’t compile on all platforms,
while the latter should compile everywhere this module can run.

This distribution’s `Makefile.PL` implements logic to determine which
backend to use.

You’re free, of course, to implement your own WASI imports rather than to
use wasm3’s. Depending on how much of WASI you actually need that may not
be as onerous as it sounds; see the distribution’s `t/wasi_pp.t` for an
example.

# MEMORY LEAK DETECTION

To help you avoid memory leaks, instances of all classes `warn()`
if their `DESTROY()` method runs at global destruction time.

This necessitates extra care when linking Perl functions to WASM;
see [Wasm::Wasm3::Module](https://metacpan.org/pod/Wasm%3A%3AWasm3%3A%3AModule) for details, and the distribution’s
`t/wasi_pp.t` for an example.

# DOCUMENTATION

This module generally documents only those aspects of its usage that
are germane to this module specifically. For more details, see
wasm3’s documentation.

# STATIC FUNCTIONS & CONSTANTS

## ($MAJOR, $MINOR, $REV) = M3\_VERSION

Returns wasm3’s version as 3 integers.

## $STRING = M3\_VERSION\_STRING

Returns wasm3’s version as a string.

## `TYPE_I32`, `TYPE_I64`, `TYPE_F32`, `TYPE_F64`

Numeric constants that indicate the corresponding WebAssembly type.

## $YN = WASI\_BACKEND

Either `uvwasi` or `simple`. See above about WASI support for
details.

# METHODS

## $OBJ = _CLASS_->new()

Instantiates _CLASS_.
Creates a new wasm3 environment and binds it to the returned object.

## $RUNTIME = _OBJ_->create\_runtime( $STACKSIZE )

Creates a new wasm3 runtime from _OBJ_.
Returns a [Wasm::Wasm3::Runtime](https://metacpan.org/pod/Wasm%3A%3AWasm3%3A%3ARuntime) instance.

## $MODULE = _OBJ_->parse\_module( $WASM\_BINARY )

Loads a WebAssembly module from _binary_ (`*.wasm`) format.
Returns a [Wasm::Wasm3::Module](https://metacpan.org/pod/Wasm%3A%3AWasm3%3A%3AModule) instance.

If your WebAssembly module is in text format rather than binary,
you’ll need to convert it first. Try
[wabt](https://github.com/webassembly/wabt) if you need such a tool.

# LICENSE & COPYRIGHT

Copyright 2022 Gasper Software Consulting. All rights reserved.

This library is licensed under the same terms as Perl itself.
See [perlartistic](https://metacpan.org/pod/perlartistic).
