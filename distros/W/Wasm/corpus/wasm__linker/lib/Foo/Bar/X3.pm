package Foo::Bar::X3;

use strict;
use warnings;
use Wasm
  -api => 0,
  -global => [ 'x3', 'i32', 'var', 42];

sub hello
{
  print "hello, world!\n";
}

1;
