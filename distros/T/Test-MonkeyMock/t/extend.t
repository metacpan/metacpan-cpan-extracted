use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Test::MonkeyMock;

package MyClass;
use strict;
use warnings;

sub new {
    my $class = shift;

    my $self = {@_};
    bless $self, $class;

    return $self;
}

sub foo { shift->{foo} }
sub bar { shift->{bar} }
sub me  { shift }

package MyNotHashClass;

sub new {
    my $class = shift;

    my $self = [];
    bless $self, $class;

    return $self;
}
sub foo { 'old' }

package main;

subtest 'mock existing method' => sub {
    my $mock = Test::MonkeyMock->new(MyClass->new(foo => 'foo', bar => 'bar'));
    $mock->mock(foo => sub { 'bar' });

    is($mock->foo, 'bar');
};

subtest 'mock several existing methods' => sub {
    my $mock = Test::MonkeyMock->new(MyClass->new(foo => 'foo', bar => 'bar'));
    $mock->mock(foo => sub { 'bar' });
    $mock->mock(bar => sub { 'baz' });

    is($mock->foo, 'bar');
    is($mock->bar, 'baz');
};

subtest 'mock existing method with options' => sub {
    my $mock = Test::MonkeyMock->new(MyClass->new(foo => 'foo', bar => 'bar'));
    $mock->mock(foo => sub { 'bar' }, when => sub { @_ == 2 });
    $mock->mock(foo => sub { 'else' });

    is($mock->foo(1), 'bar');
    is($mock->foo,    'else');
};

subtest 'mock not hash based object' => sub {
    my $mock = Test::MonkeyMock->new(MyNotHashClass->new());
    $mock->mock(foo => sub { 'bar' });

    is($mock->foo, 'bar');
};

subtest 'copy instance state' => sub {
    my $mock = Test::MonkeyMock->new(MyClass->new(foo => 'foo', bar => 'bar'));

    is($mock->{foo}, 'foo');
};

subtest 'pass isa testing' => sub {
    my $mock = Test::MonkeyMock->new(MyClass->new(foo => 'foo', bar => 'bar'));

    ok($mock->me->isa('MyClass'));
};

subtest 'return sub ref on can' => sub {
    my $mock = Test::MonkeyMock->new(MyClass->new(foo => 'foo', bar => 'bar'));

    ok(ref $mock->can('foo') eq 'CODE');
};

subtest 'thrown when mocking unknown method' => sub {
    my $mock = Test::MonkeyMock->new(MyClass->new(foo => 'foo', bar => 'bar'));

    like(
        exception {
            $mock->mock('unknown_method' => sub { 'haha' });
        },
        qr/Unknown method 'unknown_method'/
    );
};

subtest 'remember how many times not mocked method was called' => sub {
    my $mock = Test::MonkeyMock->new(MyClass->new(foo => 'foo', bar => 'bar'));

    $mock->mock('foo');

    $mock->foo;
    $mock->foo;
    $mock->foo;

    is($mock->mocked_called('foo'), 3);
};

subtest 'remember how many times mocked method was called' => sub {
    my $mock = Test::MonkeyMock->new(MyClass->new(foo => 'foo', bar => 'bar'));
    $mock->mock(foo => sub { 'bar' });

    $mock->foo;
    $mock->foo;
    $mock->foo;

    is($mock->mocked_called('foo'), 3);
};

subtest 'remember the call stack' => sub {
    my $mock = Test::MonkeyMock->new(MyClass->new(foo => 'foo', bar => 'bar'));
    $mock->mock(foo => sub { 'bar' });

    $mock->foo;
    $mock->foo(1);
    $mock->foo('Hi there!');

    is_deeply($mock->mocked_call_stack('foo'), [[], [1], ['Hi there!']]);
};

subtest 'return call stack by index' => sub {
    my $mock = Test::MonkeyMock->new(MyClass->new(foo => 'foo', bar => 'bar'));
    $mock->mock(foo => sub { 'bar' });

    $mock->foo;
    $mock->foo(1);
    $mock->foo('Hi there!');

    is_deeply([$mock->mocked_call_args('foo', 0)], []);
    is_deeply([$mock->mocked_call_args('foo', 1)], [1]);
    is_deeply([$mock->mocked_call_args('foo', 2)], ['Hi there!']);
};

subtest 'correctly builds class name' => sub {
    my $mock = Test::MonkeyMock->new(MyClass->new);
    like ref($mock), qr/Test::MonkeyMock::MyClass::__instance__\d+/;

    $mock->mock(foo => sub { });
    like ref($mock), qr/Test::MonkeyMock::MyClass::__instance__\d+/;

    $mock->mock(bar => sub { });
    like ref($mock), qr/Test::MonkeyMock::MyClass::__instance__\d+/;
};

subtest 'throw on unknown frame' => sub {
    my $mock = Test::MonkeyMock->new(MyClass->new(foo => 'foo', bar => 'bar'));
    $mock->mock(foo => sub { 'bar' });

    $mock->foo;

    like(exception { $mock->mocked_call_args('foo', 1) },
        qr/Unknown frame '1'/);
};

subtest 'throw on unmocked method when counting calls' => sub {
    my $mock = Test::MonkeyMock->new(MyClass->new(foo => 'foo', bar => 'bar'));

    like(exception { $mock->mocked_called('unknown_method') },
        qr/Unknown method 'unknown_method'/);
};

subtest 'throw on unknown method when getting stack' => sub {
    my $mock = Test::MonkeyMock->new(MyClass->new(foo => 'foo', bar => 'bar'));

    like(exception { $mock->mocked_call_args('unknown_method') },
        qr/Unknown method 'unknown_method'/);
};

subtest 'remember the return stack' => sub {
    my $mock = Test::MonkeyMock->new(MyClass->new(foo => 'foo', bar => 'bar'));

    my @return = (qw/bar baz qux/);
    $mock->mock(foo => sub { shift @return });

    $mock->foo;
    $mock->foo;
    $mock->foo;

    is_deeply($mock->mocked_return_stack('foo'), [['bar'], ['baz'], ['qux']]);
};

subtest 'return return stack by index' => sub {
    my $mock = Test::MonkeyMock->new(MyClass->new(foo => 'foo', bar => 'bar'));

    my @return = (qw/bar baz qux/);
    $mock->mock(foo => sub { shift @return });

    $mock->foo;
    $mock->foo;
    $mock->foo;

    is_deeply([$mock->mocked_return_args('foo', 0)], ['bar']);
    is_deeply([$mock->mocked_return_args('foo', 1)], ['baz']);
    is_deeply([$mock->mocked_return_args('foo', 2)], ['qux']);
};

subtest 'mock method with aliasing' => sub {
    my $mock = Test::MonkeyMock->new(MyClass->new());
    $mock->mock(foo => sub { $_[1] = '123' });

    $mock->foo(my $bar);

    is $bar, '123';
};

done_testing;
