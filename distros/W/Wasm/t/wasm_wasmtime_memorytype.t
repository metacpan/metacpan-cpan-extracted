use 5.008004;
use Test2::V0 -no_srand => 1;
use lib 't/lib';
use Test2::Tools::Wasm;
use Wasm::Wasmtime::MemoryType;

is(
  wasm_module_ok(q{
    (module
      (memory (export "frooble") 2 6)
    )
  }),
  object {
    call exports => object {
      call frooble => object {
        call [ isa => 'Wasm::Wasmtime::MemoryType' ] => T();
        call limits => [2,6];
        call is_functype   => F();
        call is_globaltype => F();
        call is_tabletype  => F();
        call is_memorytype => T();
        call kind          => 'memorytype';
        call to_string     => '2 6';
      };
    };
  },
  'memorytype class basics',
);

is(
  Wasm::Wasmtime::MemoryType->new([2,3]),
  object {
    call [ isa => 'Wasm::Wasmtime::MemoryType' ] => T();
    call limits    => [2,3];
    call to_string => '2 3';
  },
  'standalone',
);

done_testing;
