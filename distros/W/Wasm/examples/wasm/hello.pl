use strict;
use warnings;

sub hello
{
  print "Hello from Perl!\n";
}

use Wasm
  -api => 0,
  -wat => q{
    (module
      (func $hello (import "main" "hello"))
      (func (export "run") (call $hello))
    )
  },
;

run();
