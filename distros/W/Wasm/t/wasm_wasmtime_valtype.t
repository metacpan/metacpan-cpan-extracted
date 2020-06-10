use 5.008004;
use Test2::V0 -no_srand => 1;
use Wasm::Wasmtime::ValType;

foreach my $name (qw( i32 i64 f32 f64 anyref funcref ))
{
  my $vt = Wasm::Wasmtime::ValType->new($name);
  pass 'created $name';
  is(
    $vt,
    object {
      call [ isa => 'Wasm::Wasmtime::ValType' ] => T();
      call kind => $name;
      call to_string => $name;
      call kind_num => match qr/^[0-9]+$/;
    },
    "use $name",
  );
  undef $vt;
  pass "deleted $name";
}

done_testing;
