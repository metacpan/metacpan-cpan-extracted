use strict;
use Test::More;

package Bar;
sub foo {42}
use namespace::clean::xs;

package Foo;
BEGIN {
    our @ISA = qw/Bar/;
    ::is(Foo->foo, 42);
}

package main;
is(!!Foo->can('foo'), '');
is(!!Bar->can('foo'), '');

done_testing;
