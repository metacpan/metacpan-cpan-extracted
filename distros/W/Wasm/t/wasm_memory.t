use 5.008004;
use Test2::V0 -no_srand => 1;
use Test2::Plugin::Wasm;
use Wasm::Wasmtime::Store;
use Wasm::Wasmtime::Memory;
use Wasm::Memory qw( wasm_caller_memory );

my $store = Wasm::Wasmtime::Store->new;

is(
  Wasm::Memory->new(
    Wasm::Wasmtime::Memory->new(
      $store, [5,10],
    )
  ),
  object {
    call [ isa => 'Wasm::Memory' ] => T();
    call address => match qr/^[0-9]+$/;
    call size    => 327680;
    call_list limits => [ 5, 5, 10 ];
    call [ grow => 2 ] => T();
    call_list limits => [ 7, 5, 10 ];
  },
  'create a memory object'
);

imported_ok 'wasm_caller_memory';

{
  my $memory;
  {
    sub hello
    {
      $memory = wasm_caller_memory;
    }

    use Wasm
      -api => 0,
      -wat => q{
        (module
          (func $hello (import "main" "hello"))
          (func (export "run") (call $hello))
          (memory (export "memory") 2 3)
        )
      }
    ;
    run();
  }

  isa_ok $memory, 'Wasm::Memory';
  is wasm_caller_memory(), U();
}

done_testing;
