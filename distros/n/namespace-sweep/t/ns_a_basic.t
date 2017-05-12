#!/usr/bin/env perl

# This test file is from the namespace::autoclean distribution (t/basic.t)

use strict;
use warnings;
use Test::More tests => 6;

{
    package Foo;
    use Sub::Name;
    sub bar { }
    use namespace::sweep;
    sub moo { }
    BEGIN { *kooh = *kooh = do { package Moo; sub { }; }; }
    BEGIN { *affe = *affe = sub { }; }
    BEGIN { *tiger = *tiger = subname tiger => sub { }; }
}

ok( Foo->can('bar'));
ok( Foo->can('moo'));
ok(!Foo->can('kooh'));
ok( Foo->can('affe'));
ok( Foo->can('tiger'));
ok(!Foo->can('subname'));
