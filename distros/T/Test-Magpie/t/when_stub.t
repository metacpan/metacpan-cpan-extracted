#!/usr/bin/perl -T
use strict;
use warnings;

use Test::More;
use Test::Fatal;

BEGIN { use_ok 'Test::Magpie', qw(mock when) }

use aliased 'Test::Magpie::Invocation';
use Test::Magpie::Util qw( get_attribute_value );
use Test::Magpie::ArgumentMatcher qw( anything );
use Throwable;

my $mock = mock;
my $when;
my $stubs = get_attribute_value($mock, 'stubs');

subtest 'when()' => sub {
    $when = when($mock);
    isa_ok $when, 'Test::Magpie::When';

    is get_attribute_value($when, 'mock'), $mock, 'has mock';

    like exception { when() },
        qr/^when\(\) must be given a mock object/,
        'no arg';
    like exception { when('string') },
        qr/^when\(\) must be given a mock object/,
        'invalid arg';
};

subtest 'when->invoked' => sub {
    my @args = ([], [123, bar => 456]);

    for (@args) {
        my $stub = $when->foo(@$_);
        isa_ok $stub, 'Test::Magpie::Stub';
        is $stubs->{foo}[-1], $stub,      'stored';

        is $stub->method_name, 'foo',     'method_name';
        is_deeply [$stub->arguments], $_, 'arguments';
    }
};

subtest 'then_return' => sub {
    my $stub = when($mock)->foo;
    is $stub->then_return(qw[ bar baz ]), $stub;
    is $stub->then_return(qw[ bar baz ]), $stub;

    is $mock->foo, 'bar', 'returns (scalar context)';
    is_deeply [$mock->foo], [qw( bar baz )], 'returns (array context)';
    is $mock->foo, undef, 'no stubs left';
};

{
    package NonThrowable;
    use Moose;
    use overload '""' => \&message;
    sub message {'died'}
}
{
    package ThrowableException;
    use Moose;
    with 'Throwable';
    use overload '""' => \&message;
    sub message {'exception thrown'}
}

subtest 'then_die' => sub {
    my $dog = mock;
    my $stub = when($dog)->meow;
    is $stub
        ->then_die( 'dunno how' )
        ->then_die( NonThrowable->new )
        ->then_die( ThrowableException->new ),
            $stub, 'chainable';

    like exception { $dog->meow }, qr/^dunno how/, 'died';
    like exception { $dog->meow }, qr/^died/, 'died (blessed, cannot throw)';
    like exception { $dog->meow }, qr/^exception thrown/, 'exception';
    is $dog->meow, undef, 'no stubs left';
};

subtest 'consecutive' => sub {
    my $iterator = mock;
    when($iterator)
        ->next
            ->then_return(1)
            ->then_return(2)
            ->then_die('Out of numbers');

    is $iterator->next, 1;
    is $iterator->next, 2;
    like exception { $iterator->next }, qr/^Out of numbers/;
    is $iterator->next, undef, 'no stubs left';
};

subtest 'argument matching' => sub {
    my $list = mock;
    when($list)->get(0)->then_return('first');
    when($list)->get(1)->then_return('second');
    when($list)->get()->then_die('no index given');
    when($list)->get(anything)->then_die('index out of bounds');

    like exception { $list->get(-1) }, qr/index out of bounds/,
        'argument matcher';

    ok ! $list->set(0, '1st'), 'no such method';
    ok ! $list->get(0, 1),     'extra args';

    is $list->get(0), 'first', 'exact match';
    is $list->get(1), 'second';
    like exception { $list->get() }, qr/^no index given/, 'no args';
};

done_testing(7);
