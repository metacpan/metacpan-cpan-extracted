#!/usr/bin/env perl

# This test file is from the namespace::autoclean distribution (t/also.t)

use strict;
use warnings;
use Test::More tests => 3;

{
    package Foo;
    use namespace::sweep -also => ['bar'];
    use namespace::sweep -also => 'moo';
    sub bar {}
    sub moo {}
    sub baz {}
}

ok(!Foo->can('bar'), '-also works');
ok(!Foo->can('moo'), '-also works with string argument');
ok( Foo->can('baz'), 'method not specified in -also remains');

