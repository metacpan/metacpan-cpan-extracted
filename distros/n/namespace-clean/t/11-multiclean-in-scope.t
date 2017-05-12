use strict;
use warnings;

use Test::More tests => 13;

eval q{
  package Class1;
  sub cleaned1 {}
  use namespace::clean;
  1;
} or die $@;

ok !Class1->can('cleaned1'), 'basic clean';

eval q{
  package Class1;
  sub cleaned2 {}
  use namespace::clean;
  1;
} or die $@;

ok !Class1->can('cleaned2'), 'clean same class again';

eval q{
  package Class2;
  sub cleaned1 {}
  use namespace::clean;
  sub left1 {}
  no namespace::clean;
  sub cleaned2 {}
  use namespace::clean;
  1;
} or die $@;

ok !Class2->can('cleaned1'), 'basic clean before no';
ok +Class2->can('left1'),    'basic no clean';
ok !Class2->can('cleaned2'), 'basic clean after no';

eval q{
  package Class2;
  sub cleaned3 {}
  use namespace::clean;
  sub left2 {}
  no namespace::clean;
  sub cleaned4 {}
  use namespace::clean;
  1;
} or die $@;

ok !Class2->can('cleaned3'),  'clean again before no';
ok +Class2->can('left2'),     'clean again no clean';
ok !Class2->can('cleaned4'),  'clean again after no';

eval q{
  package Class3;
  sub cleaned1 {}
  use namespace::clean;
  sub cleaned2 {}
  no namespace::clean;
  {
    sub cleaned3 {}
    use namespace::clean;
  }
  BEGIN {
    package main;
    ok !Class3->can('cleaned3'), 'clean inner scope';
    {
      local $TODO = 'unable to differentiate scopes';
      ok +Class3->can('cleaned1'), 'clean inner scope leaves outer';
    }
    ok +Class3->can('cleaned2'), 'clean inner scope leaves outer no';
  }
  use namespace::clean;
  1;
} or die $@;

ok !Class3->can('cleaned1'), 'clean after scoped';
ok +Class3->can('cleaned2'), 'no clean after scoped';
