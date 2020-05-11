use strict;
use warnings;
use Wasm
  -api => 0,
  -wat => q{
    (module
      (global (export "global") (mut i32) (i32.const 42))
    )
  }
;

print "$global\n";  # 42
$global = 99;
print "$global\n";  # 99

