#!/usr/bin/perl -T
use strict;
use warnings;

use Test::More;
use Test::Fatal;

BEGIN { use_ok 'Test::Magpie', qw(mock when) }

use Test::Magpie::ArgumentMatcher qw( anything );
use Test::Magpie::Util qw( get_attribute_value );

use constant {
    Mock       => 'Test::Magpie::Mock',
    Invocation => 'Test::Magpie::Invocation',
};

subtest 'mock()' => sub {
    my $mock = mock;
    ok $mock, 'mock()';

    isa_ok $mock, 'Bar';
    ok $mock->isa('Bar'),  'isa anything';

    ok $mock->does('Baz'), 'does anything';
    ok $mock->DOES('Baz'), 'DOES anything';

    is ref($mock), Mock,   'no ref';

    subtest 'can' => sub {
        can_ok $mock, qw(foo bar baz);

        my $coderef = $mock->can('can_method');
        $coderef->($mock, 'baz', 123);

        my $invocation = get_attribute_value($mock, 'invocations')->[-1];
        is $invocation->method_name, 'can_method',        'method_name';
        is_deeply [$invocation->arguments], ['baz', 123], 'arguments';
    };
};

subtest 'mock(class)' => sub {
    my $mock = mock('Foo');
    ok $mock,             'mock(class)';
    is ref($mock), 'Foo', 'ref';

    like exception {mock($mock)},
        qr/^The argument for mock\(\) must be a string/,
        'arg exception';
};

done_testing(3);
