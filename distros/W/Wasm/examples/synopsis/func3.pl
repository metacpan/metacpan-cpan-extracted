use strict;
use warnings;
use Wasm
  -api => 0,
  -wat => q{
    (module
      (func (export "add") (param i32 i32) (result i32)
       local.get 0
       local.get 1
       i32.add)
    )
  }
;

print add(1,2), "\n";  # 3
