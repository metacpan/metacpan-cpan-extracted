use strict;
use warnings;
use Wasm::Wasmtime;
use Wasm::Wasmtime::Caller qw( wasmtime_caller );

{
  # this just uses Platypus to create a utility function
  # to convert a pointer to a C string into a Perl string.
  use FFI::Platypus 1.00;
  my $ffi = FFI::Platypus->new( api => 1 );
  $ffi->attach_cast( 'cstring' => 'opaque' => 'string' );
}

sub print_wasm_string
{
  my $ptr = shift;
  my $caller = wasmtime_caller;
  my $memory = $caller->export_get('memory');
  print cstring($ptr + $memory->data);
}

my $instance = Wasm::Wasmtime::Instance->new(
  Wasm::Wasmtime::Module->new(wat => q{
    (module
      (import "" "print_wasm_string" (func $print_wasm_string (param i32)))
      (func (export "run")
        i32.const 0
        call $print_wasm_string
      )
      (memory (export "memory") 1)
      (data (i32.const 0) "Hello, world!\n\00")
    )
  }),
  [\&print_wasm_string],
);

$instance->exports->run->();
