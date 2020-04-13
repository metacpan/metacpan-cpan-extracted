use strict;
use warnings;
use Wasm::Wasmtime;

my $store = Wasm::Wasmtime::Store->new;
my $config = Wasm::Wasmtime::WasiConfig->new;

# inherit everything, and provide access to the
# host filesystem under /host (yikes!)
$config->inherit_argv;
$config->inherit_env;
$config->inherit_stdin;
$config->inherit_stdout;
$config->inherit_stderr;
$config->preopen_dir("/", "/host");

my $wasi = Wasm::Wasmtime::WasiInstance->new($store, "wasi_snapshot_preview1", $config);
