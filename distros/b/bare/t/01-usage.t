#!perl -w

use strict;
use Test::More tests => 7;

use lib "./blib/lib";

{
  use bare qw( foo bar );
  foo=2;
  bar=4;
  ok(foo==2);
  ok(bar==4);
}

SKIP: {
  if(!$^V || $^V lt v5.8.0) {
    skip "no utf8 support due to lack of utf8 sub names on perl <= v5.8.0", 3;
  }
  eval '
    use utf8;
    use bare qw(şkí);
    şkí=3;
    ok(şkí==3);
    ok(foo);
  ';
  ok(!$@);
}


{ 
  local $foo=5;
  ok(foo==5);
}

ok(foo==2);


