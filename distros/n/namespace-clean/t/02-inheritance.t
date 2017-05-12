use warnings;
use strict;

use lib 't/lib';
use Test::More tests => 10;

use_ok('Inheritance');
ok( !InheritanceParent->can('foo'),
    'function removed in parent' );
ok( InheritanceParent->can('bar'),
    'method still in parent' );
is( InheritanceParent->bar, 23,
    'method works, function still bound' );
ok( !Inheritance->can('baz'),
    'function removed in subclass' );
ok( Inheritance->can('qux'),
    'method still in subclass' );
ok( !Inheritance->can('foo'),
    'parent function not available in subclass' );
ok( Inheritance->can('bar'),
    'parent method available in subclass' );
is( Inheritance->bar, 23,
    'parent method works in subclass' );
is( Inheritance->qux, 23,
    'subclass method calls to parent work' );

