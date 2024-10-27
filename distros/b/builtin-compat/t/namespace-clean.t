use strict;
use warnings;
use Test::More;

{
  package Foo;
  sub bar { 1 }

  use builtin::compat;
}

eval { Foo::bar() };
ok( ! length $@, 'nothing to clean' );

done_testing;
