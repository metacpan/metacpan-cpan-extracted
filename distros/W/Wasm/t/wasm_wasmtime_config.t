use Test2::V0 -no_srand => 1;
use Wasm::Wasmtime::Config;

my $config = Wasm::Wasmtime::Config->new;
isa_ok $config, 'Wasm::Wasmtime::Config';

$config->debug_info(0);
$config->debug_info(1);
pass 'debug_info';

$config->wasm_threads(0);
$config->wasm_threads(1);
pass 'wasm_threads';

$config->wasm_reference_types(0);
$config->wasm_reference_types(1);
pass 'wasm_reference_types';

$config->wasm_simd(0);
$config->wasm_simd(1);
pass 'wasm_simd';

$config->wasm_bulk_memory(0);
$config->wasm_bulk_memory(1);
pass 'wasm_bulk_memory';

$config->wasm_multi_value(0);
$config->wasm_multi_value(1);
pass 'wasm_multi_value';

foreach my $strategy (qw( auto cranelift lightbeam ))
{
  if(my $e = dies { $config->strategy($strategy) })
  {
    is(
      $e,
      mismatch qr/unknown strategy:/,
      "strategy($strategy) = fail",
    );
    note "exception: $e";
  }
  else
  {
    pass "strategy($strategy) = ok";
  }
}

is
  dies { $config->strategy('foo') },
  match qr/unknown strategy: foo/,
  'strategy: unknown strategy'
;

$config->cranelift_debug_verifier(0);
$config->cranelift_debug_verifier(1);
pass 'cranelift_debug_verifier';

foreach my $cranelift_opt_level (qw( none speed speed_and_size ))
{
  $config->cranelift_opt_level($cranelift_opt_level);
  pass "cranelift_opt_level($cranelift_opt_level) = ok";
}

is
  dies { $config->cranelift_opt_level('foo') },
  match qr/unknown cranelift_opt_level: foo/,
  'cranelift_opt_level: unknown cranelift_opt_level'
;

foreach my $profiler (qw( none jitdump ))
{
  if(my $e = dies { $config->profiler($profiler) })
  {
    is(
      $e,
      mismatch qr/unknown profiler:/,
      "profiler($profiler) = fail",
    );
    note "exception: $e";
  }
  else
  {
    pass "profiler($profiler) = ok";
  }
}

is
  dies { $config->profiler('foo') },
  match qr/unknown profiler: foo/,
  'profiler: unknown profiler'
;

done_testing;
