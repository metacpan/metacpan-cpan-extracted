use strict;
use warnings;
sub hello {
  print "hello world!\n";
}

use Wasm
  -api => 0,
  -wat => q{
    (module
      (func $hello (import "main" "hello"))
      (func (export "run") (call $hello))
    )
  }
;

run();   # hello world!
