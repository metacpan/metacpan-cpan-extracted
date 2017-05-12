use strict;
use warnings;
use Test::More 0.88;

{
    package Foo;
    use namespace::autoclean -also => ['bar'];
    use namespace::autoclean -also => 'moo';
    sub bar {}
    sub moo {}
    sub baz {}
}

ok(!Foo->can('bar'), '-also works');
ok(!Foo->can('moo'), '-also works with string argument');
ok( Foo->can('baz'), 'method not specified in -also remains');

done_testing();
