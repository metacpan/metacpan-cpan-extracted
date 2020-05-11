use Test2::V0 -no_srand => 1;
use Wasm::Wasmtime::Store;
use Wasm::Wasmtime::Memory;
use Wasm::Memory;

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


done_testing;
