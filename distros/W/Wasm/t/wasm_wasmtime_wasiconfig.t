use 5.008004;
use Test2::V0 -no_srand => 1;
use Wasm::Wasmtime::WasiConfig;
use File::Temp qw( tempdir );
use Path::Tiny qw( path );

is(
  Wasm::Wasmtime::WasiConfig->new,
  object {
    call [ isa => 'Wasm::Wasmtime::WasiConfig' ] => T();
  },
  'default'
);

foreach my $method (map { "inherit_$_" } qw( argv env stdin stdout stderr ))
{
  try_ok {
    Wasm::Wasmtime::WasiConfig
      ->new
      ->$method
  } "$method";
}

try_ok {
  Wasm::Wasmtime::WasiConfig
    ->new
    ->set_argv("hello","world")
} "set_argv";

try_ok {
  Wasm::Wasmtime::WasiConfig
    ->new
    ->set_env(foo => "bar", baz => 2)
} "set_env";

try_ok {
  Wasm::Wasmtime::WasiConfig
    ->new
    ->set_stdin_file(__FILE__)
} "set_stdin_file";

try_ok {
  my $file = path(tempdir(CLEANUP => 1))->child('foo.txt');
  Wasm::Wasmtime::WasiConfig
    ->new
    ->set_stdout_file("$file")
} "set_stdout_file";

try_ok {
  my $file = path(tempdir(CLEANUP => 1))->child('foo.txt');
  Wasm::Wasmtime::WasiConfig
    ->new
    ->set_stderr_file("$file")
} "set_stderr_file";

try_ok {
  my $dir = path(tempdir(CLEANUP => 1));
  Wasm::Wasmtime::WasiConfig
    ->new
    ->preopen_dir("$dir", "/foo/bar")
} "preopen_dir";

done_testing;
