use strict;
use warnings;

use Test::More tests => 4;

{
  package Bar;
  use sort 'stable';
  use namespace::clean;
  use sort 'stable';
  {
    1;
  }

  Test::More::pass('no segfault');
}

{
  package Foo;
  BEGIN {
    $^H{'foo'} = 'bar';
  }

  use namespace::clean;

  BEGIN {
    Test::More::is( $^H{'foo'}, 'bar', 'compiletime hinthash intact after n::c' );
  }

  {
    BEGIN {
      Test::More::is(
        $^H{'foo'}, 'bar', 'compile-time hinthash intact in inner scope'
      );
    }
    1;
  }

  BEGIN {
    SKIP: {
      Test::More::skip(
        'Tied hinthash values not present in extended caller() on perls older than 5.10'
       .', regardless of mode (PP or XS)',
        1
      ) if ("$]" < 5.010_000);
      package DB;
      Test::More::is( ( (caller(0))[10] || {} )->{foo}, 'bar', 'hinthash values visible in caller' );
    }
  }
}
