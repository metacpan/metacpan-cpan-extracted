use strict;
use warnings;
use Wasm::Wasmtime;
use Path::Tiny qw( path );

# Example of instantiating two modules which link to each other.
my $store = Wasm::Wasmtime::Store->new;

# First set up our linker which is going to be linking modules together. We
# want our linker to have wasi available, so we set that up here as well.
my $linker = Wasm::Wasmtime::Linker->new($store);
my $wasi = Wasm::Wasmtime::WasiInstance->new(
  $store,
  "wasi_snapshot_preview1",
  Wasm::Wasmtime::WasiConfig
    ->new
    ->inherit_stdout
);
$linker->define_wasi($wasi);

# Load and compile our two modules
my $module1 = Wasm::Wasmtime::Module->new($store, file => path(__FILE__)->parent->child('linking1.wat') );
my $module2 = Wasm::Wasmtime::Module->new($store, file => path(__FILE__)->parent->child('linking2.wat') );

# Instantiate our first module which only uses WASI, then register that
# instance with the linker since the next linking will use it.
my $instance2 = $linker->instantiate($module2);
$linker->define_instance("linking2", $instance2);

# And with that we can perform the final link and the execute the module.
my $instance1 = $linker->instantiate($module1);
my $run = $instance1->get_export('run')->as_func;
$run->();
