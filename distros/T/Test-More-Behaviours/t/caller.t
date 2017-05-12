#!perl -w

use strict;

{
    package Foo;
    use Test::More::Behaviours 'no_plan';

    sub foo {
        test 'caller() is not munged' => sub {
            is_deeply [caller], ['Foo', $0, 19], 'basic caller()' or diag join " ", caller;
            is_deeply [(caller(0))[0..7]],
                      ['Foo', $0, 19, 'Foo::foo', 1, undef, undef, undef],
                      'hardcore caller()';
        }
    }

#line 19
    foo();
}

