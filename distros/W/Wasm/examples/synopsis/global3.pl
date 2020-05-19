use strict;
use warnings;

package Foo;

use Wasm
  -api    => 0,
  -global => [
    'foo',  # name
    'i32',  # type
    'var',  # mutability
    42,     # initial value
  ]
;

package Bar;

use Wasm
  -api      => 0,
  -wat      => q{
    (module
      (global $foo (import "Foo" "foo") (mut i32))
      (func (export "get_foo") (result i32)
        (global.get $foo))
      (func (export "inc_foo")
        (global.set $foo
          (i32.add (global.get $foo) (i32.const 1))))
    )
  }
;

package main;

print Bar::get_foo(), "\n";   # 42
Bar::inc_foo();
print Bar::get_foo(), "\n";   # 43
$Foo::foo = 0;
print Bar::get_foo(), "\n";   # 0
