use 5.008004;
use Test2::V0 -no_srand => 1;
use Wasm::Wasmtime::FFI;

imported_ok '$ffi';
isa_ok $ffi, 'FFI::Platypus';

done_testing;
