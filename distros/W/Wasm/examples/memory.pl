use strict;
use warnings;
use Carp::Assert;
use Path::Tiny qw( path );
use Wasm::Wasmtime;
use PeekPoke::FFI qw( peek poke );


my $module = Wasm::Wasmtime::Module->new( file => path(__FILE__)->parent->child('memory.wat') );
my $instance = Wasm::Wasmtime::Instance->new($module);

my $memory = $instance->get_export("memory")->as_memory;
my $size   = $instance->get_export("size")->as_func;
my $load   = $instance->get_export("load")->as_func;
my $store  = $instance->get_export("store")->as_func;

print "Checking memory...\n";
assert($memory->size == 2);
assert($memory->data_size == 0x20000);

# Note that usage of `data` is unsafe! This is a raw C pointer which is not
# bounds checked at all. We checked our `data_size` above but you'll want to be
# very careful when accessing data through `data()`
assert(peek($memory->data + 0x0000) == 0);
assert(peek($memory->data + 0x1000) == 1);
assert(peek($memory->data + 0x1003) == 4);

assert($size->() == 2);
assert($load->(0) == 0);
assert($load->(0x1000) == 1);
assert($load->(0x1003) == 4);
assert($load->(0x1ffff) == 0);

# out of bounds trap
{
  local $@;
  eval { $load->(0x20000) };
  assert($@ =~ /wasm trap: out of bounds memory/);
}

print "Mutating memory...\n";
poke($memory->data + 0x1003, 5);
$store->(0x1002, 6);

#out of bounds trap
{
  local $@;
  eval { $store->(0x20000, 0) };
  assert($@ =~ /wasm trap: out of bounds memory access/);
}

assert(peek($memory->data + 0x1002) == 6);
assert(peek($memory->data + 0x1003) == 5);
assert($load->(0x1002) == 6);
assert(peek($memory->data + 0x1003) == 5);

# Grow memory
assert($memory->grow(1));
assert($memory->size == 3);
assert($memory->data_size == 0x30000);

assert($load->(0x20000) == 0);
$store->(0x20000, 0);
{
  local $@;
  eval { $load->(0x30000) };
  assert($@ =~ /wasm trap: out of bounds memory/);
}
{
  local $@;
  eval { $store->(0x30000, 0) };
  assert($@ =~ /wasm trap: out of bounds memory/);
}

# Memory can fail to grow
assert(!$memory->grow(1));
assert($memory->grow(0));

print "Creating stand-alone memory...\n";
my $memory2 = Wasm::Wasmtime::Memory->new(
  Wasm::Wasmtime::Store->new,
  Wasm::Wasmtime::MemoryType->new([5,5]),
);
assert($memory2->size() == 5);
assert(!$memory2->grow(1));
assert($memory2->grow(0));
