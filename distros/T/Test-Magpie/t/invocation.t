#!/usr/bin/perl -T
use strict;
use warnings;

use Test::More tests => 8;

BEGIN { use_ok 'Test::Magpie', 'mock' }

use aliased 'Test::Magpie::Invocation';

use Test::Magpie::ArgumentMatcher qw( anything );
use Test::Magpie::Util qw( get_attribute_value );

my $mock = mock;
ok ! $mock->foo(123, bar => 456), 'mock method invoked';

my $invocation = get_attribute_value($mock, 'invocations')->[-1];
isa_ok $invocation, Invocation;

is $invocation->method_name, 'foo',                    'method_name';
is_deeply [$invocation->arguments], [123, 'bar', 456], 'arguments';
is $invocation->as_string, 'foo(123, "bar", 456)',     'as_string';

is Invocation->new(
    method_name => 'method',
    arguments => [anything],
)->as_string, 'method(anything())', 'as_string with overloaded args';

subtest 'satisfied_by' => sub {
    ok $invocation->satisfied_by( Invocation->new(
        method_name => 'foo',
        arguments => [123, 'bar', 456]
    ) ), 'exact match';

    ok ! $invocation->satisfied_by(
        Invocation->new(
            method_name => 'bar',
            arguments => [123, 'bar', 456],
        )
    ), 'different method_name';

    ok ! $invocation->satisfied_by(
        Invocation->new(method_name => 'foo')
    ), 'no arguments';

    ok ! $invocation->satisfied_by(
        Invocation->new(
            method_name => 'foo',
            arguments => [123, 'bar'],
        )
    ), 'less arguments';

    ok ! $invocation->satisfied_by(
        Invocation->new(
            method_name => 'foo',
            arguments => [123, 'bar', 123],
        )
    ), 'different arguments';

    ok ! $invocation->satisfied_by(
        Invocation->new(
            method_name => 'foo',
            arguments => [123, 'bar', 456, 123]
        )
    ), 'more arguments';

    SKIP: {
        skip 'Not allowed: Invocation objects with argument matchers', 1;
        fail;
    }
};
