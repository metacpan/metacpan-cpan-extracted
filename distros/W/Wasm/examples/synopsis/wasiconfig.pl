use strict;
use warnings;
use Wasm::Wasmtime;

my $store = Wasm::Wasmtime::Store->new;
my $config = Wasm::Wasmtime::WasiConfig->new;

# inherit everything, and provide access to the
# host filesystem under /host (yikes!)
$config->inherit_argv
       ->inherit_env
       ->inherit_stdin
       ->inherit_stdout
       ->inherit_stderr
       ->preopen_dir("/", "/host");

my $wasi = Wasm::Wasmtime::WasiInstance->new(
  $store,
  "wasi_snapshot_preview1",
  $config,
);
