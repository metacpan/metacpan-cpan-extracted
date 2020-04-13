use strict;
use warnings;
use Wasm::Wasmtime;
use PeekPoke::FFI qw( poke );

my $store = Wasm::Wasmtime::Store->new;

my $module = Wasm::Wasmtime::Module->new($store, wat => q{
  (module

    ;; callback we can make back into perl space
    (func $hello (import "" "hello"))
    (func (export "call_hello") (call $hello))

    ;; plain WebAssembly function that we can call from Perl
    (func (export "gcd") (param i32 i32) (result i32)
      (local i32)
      block  ;; label = @1
        block  ;; label = @2
          local.get 0
          br_if 0 (;@2;)
          local.get 1
          local.set 2
          br 1 (;@1;)
        end
        loop  ;; label = @2
          local.get 1
          local.get 0
          local.tee 2
          i32.rem_u
          local.set 0
          local.get 2
          local.set 1
          local.get 0
          br_if 0 (;@2;)
        end
      end
      local.get 2
    )

    ;; memory region that can be accessed from
    ;; either Perl or WebAssembly
    (memory (export "memory") 2 3)
    (func (export "load") (param i32) (result i32)
      (i32.load8_s (local.get 0))
    )

  )
});

sub hello
{
  print "hello world!\n";
}

my $instance = Wasm::Wasmtime::Instance->new( $module, [\&hello] );

# call a WebAssembly function that calls back into Perl space
$instance->get_export('call_hello')->as_func;

# call plain WebAssembly function
my $gcd = $instance->get_export('gcd')->as_func;
print $gcd->(6,27), "\n";      # 3

# write to memory from Perl and read it from WebAssembly
my $memory = $instance->get_export('memory')->as_memory;
poke($memory->data + 10, 42);  # set offset 10 to 42
my $load = $instance->get_export('load')->as_func;
print $load->(10), "\n";       # 42
poke($memory->data + 10, 52);  # set offset 10 to 52
print $load->(10), "\n";       # 52
