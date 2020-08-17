package Wasm::Wasmtime;

use strict;
use warnings;
use 5.008004;
use Wasm::Wasmtime::Caller;
use Wasm::Wasmtime::Config;
use Wasm::Wasmtime::Engine;
use Wasm::Wasmtime::ExportType;
use Wasm::Wasmtime::Extern;
use Wasm::Wasmtime::ExternType;
use Wasm::Wasmtime::Func;
use Wasm::Wasmtime::FuncType;
use Wasm::Wasmtime::Global;
use Wasm::Wasmtime::GlobalType;
use Wasm::Wasmtime::ImportType;
use Wasm::Wasmtime::Instance;
use Wasm::Wasmtime::Linker;
use Wasm::Wasmtime::Module;
use Wasm::Wasmtime::Store;
use Wasm::Wasmtime::TableType;
use Wasm::Wasmtime::Trap;
use Wasm::Wasmtime::ValType;
use Wasm::Wasmtime::WasiConfig;
use Wasm::Wasmtime::WasiInstance;

# ABSTRACT: Perl interface to Wasmtime
our $VERSION = '0.19'; # VERSION


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Wasm::Wasmtime - Perl interface to Wasmtime

=head1 VERSION

version 0.19

=head1 SYNOPSIS

 use Wasm::Wasmtime;
 use PeekPoke::FFI qw( poke );
 
 my $store = Wasm::Wasmtime::Store->new;
 
 my $module = Wasm::Wasmtime::Module->new($store->engine, wat => q{
   (module
 
     ;; callback we can make back into perl space
     (func $hello (import "" "hello"))
     (func (export "call_hello") (call $hello))
 
     ;; plain WebAssembly function that we can call from Perl
     (func (export "gcd") (param i32 i32) (result i32)
       (local i32)
       block  ;; label = @1
         block  ;; label = @2
           local.get 0
           br_if 0 (;@2;)
           local.get 1
           local.set 2
           br 1 (;@1;)
         end
         loop  ;; label = @2
           local.get 1
           local.get 0
           local.tee 2
           i32.rem_u
           local.set 0
           local.get 2
           local.set 1
           local.get 0
           br_if 0 (;@2;)
         end
       end
       local.get 2
     )
 
     ;; memory region that can be accessed from
     ;; either Perl or WebAssembly
     (memory (export "memory") 2 3)
     (func (export "load") (param i32) (result i32)
       (i32.load8_s (local.get 0))
     )
 
   )
 });
 
 sub hello
 {
   print "hello world!\n";
 }
 
 my $instance = Wasm::Wasmtime::Instance->new( $module, $store, [\&hello] );
 
 # call a WebAssembly function that calls back into Perl space
 $instance->exports->call_hello;
 
 # call plain WebAssembly function
 my $gcd = $instance->exports->gcd;
 print $gcd->(6,27), "\n";      # 3
 
 # write to memory from Perl and read it from WebAssembly
 my $memory = $instance->exports->memory;
 poke($memory->data + 10, 42);  # set offset 10 to 42
 my $load = $instance->exports->load;
 print $load->(10), "\n";       # 42
 poke($memory->data + 10, 52);  # set offset 10 to 52
 print $load->(10), "\n";       # 52

=head1 DESCRIPTION

B<WARNING>: WebAssembly and Wasmtime are a moving target and the interface for these modules
is under active development.  Use with caution.

This module pre-loads all the relevant Wasmtime modules so that you can just start using the
appropriate classes.

If you are just getting your feet wet with WebAssembly and Perl then you probably want to
take a look at L<Wasm>, which is a simple interface that automatically imports functions
from Wasm space into Perl space.

=head1 ENVIRONMENT

=head2 PERL_WASM_WASMTIME_MEMORY

This environment variable, if set, should be a colon separated list of values for
C<static_memory_maximum_size>, C<static_memory_guard_size> and C<dynamic_memory_guard_size>.
See L<Wasm::Wasmtime::Config> for more details on these limits.

=head1 SEE ALSO

=over 4

=item L<Wasm>

Simplified interface to WebAssembly that imports WebAssembly functions into Perl space.

=item L<Wasm::Wasmtime::Module>

Interface to WebAssembly module.

=item L<Wasm::Wasmtime::Instance>

Interface to a WebAssembly module instance.

=item L<Wasm::Wasmtime::Func>

Interface to WebAssembly function.

=item L<Wasm::Wasmtime::Linker>

Link together multiple WebAssembly modules into one program.

=item L<Wasm::Wasmtime::Wat2Wasm>

Tool to convert WebAssembly Text (WAT) to WebAssembly binary (Wasm).

=item L<Wasm::Wasmtime::WasiInstance>

WebAssembly System Interface (WASI).

=item L<https://github.com/bytecodealliance/wasmtime>

The rust library used by this module, via its C API, via FFI.

=item L<https://github.com/bytecodealliance/wasmtime-py>

These bindings here heavily influenced by the Python Wasmtime bindings.

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
