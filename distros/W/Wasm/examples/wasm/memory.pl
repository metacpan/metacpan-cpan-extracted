use strict;
use warnings;
use Carp::Assert;
use Path::Tiny qw( path );
use PeekPoke::FFI qw( peek poke );
use Wasm
  -api => 0,
  -wat => q{
    (module
      (memory (export "memory") 2 3)

      (func (export "size") (result i32) (memory.size))
      (func (export "load") (param i32) (result i32)
        (i32.load8_s (local.get 0))
      )
      (func (export "store") (param i32 i32)
        (i32.store8 (local.get 0) (local.get 1))
      )

      (data (i32.const 0x1000) "\01\02\03\04")
    )
  }
;

print "Checking memory...\n";
assert([$memory->limits]->[0] == 2);
assert($memory->size == 0x20000);

# Note that usage of `data` is unsafe! This is a raw C pointer which is not
# bounds checked at all. We checked our `data_size` above but you'll want to be
# very careful when accessing data through `data()`
assert(peek($memory->address + 0x0000) == 0);
assert(peek($memory->address + 0x1000) == 1);
assert(peek($memory->address + 0x1003) == 4);

assert(size() == 2);
assert(load(0) == 0);
assert(load(0x1000) == 1);
assert(load(0x1003) == 4);
assert(load(0x1ffff) == 0);

# out of bounds trap
{
  local $@;
  eval { load(0x20000) };
  assert($@ =~ /wasm trap: out of bounds memory/);
}

print "Mutating memory...\n";
poke($memory->address + 0x1003, 5);
store(0x1002, 6);

#out of bounds trap
{
  local $@;
  eval { store(0x20000, 0) };
  assert($@ =~ /wasm trap: out of bounds memory access/);
}

assert(peek($memory->address + 0x1002) == 6);
assert(peek($memory->address + 0x1003) == 5);
assert(load(0x1002) == 6);
assert(peek($memory->address + 0x1003) == 5);

# Grow memory
assert($memory->grow(1));
assert([$memory->limits]->[0] == 3);
assert($memory->size == 0x30000);

assert(load(0x20000) == 0);
store(0x20000, 0);
{
  local $@;
  eval { load(0x30000) };
  assert($@ =~ /wasm trap: out of bounds memory/);
}
{
  local $@;
  eval { store(0x30000, 0) };
  assert($@ =~ /wasm trap: out of bounds memory/);
}

# Memory can fail to grow
assert(!$memory->grow(1));
assert($memory->grow(0));
