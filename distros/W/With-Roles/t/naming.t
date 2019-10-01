use strict;
use warnings;
use Test::More;

use With::Roles;

*composite_name = \&With::Roles::_composite_name;


is composite_name('Foo', [ 'Foo::Role' ], [ 'MyRole' ]),
  'Foo__WITH__MyRole';
is composite_name('Foo', [ 'Foo::Role' ], [ 'Foo::Role::MyRole' ]),
  'Foo__WITH__::MyRole';
is composite_name('Foo', [ 'Foo::Role' ], [ 'Foo::Role::MyRole', 'Foo::Role::Another' ]),
  'Foo__WITH__::MyRole__AND__::Another';
is composite_name('Foo', [ 'Foo::Role' ], [ 'Foo::Role::MyRole' ], [ 'Foo::Role::Another' ]),
  'Foo__WITH__::MyRole__WITH__::Another';

done_testing;

