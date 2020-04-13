use Test2::V0 -no_srand => 1;
use Wasm::Wasmtime::ValType;

foreach my $name (qw( i32 i64 f32 f64 anyref funcref ))
{
  is(
    Wasm::Wasmtime::ValType->new($name),
    object {
      call [ isa => 'Wasm::Wasmtime::ValType' ] => T();
      call kind => $name;
      call kind_num => match qr/^[0-9]+$/;
    },
    "created $name",
  );
}

done_testing;
