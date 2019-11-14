use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Test::MonkeyMock;

subtest 'mock method' => sub {
    my $mock = Test::MonkeyMock->new();
    $mock->mock(foo => sub { 'bar' });

    is($mock->foo, 'bar');
};

subtest 'mock mixed case' => sub {
    my $mock = Test::MonkeyMock->new();
    $mock->mock(FOO => sub { 'bar' });
    $mock->mock(Foo => sub { 'baz' });

    is($mock->FOO, 'bar');
    is($mock->Foo, 'baz');
};

subtest 'mock method with when option' => sub {
    my $mock = Test::MonkeyMock->new();
    $mock->mock(foo => sub { 'bar' }, when => sub { @_ == 2 });
    $mock->mock(foo => sub { 'else' });

    is($mock->foo(1), 'bar');
    is($mock->foo,    'else');
};

subtest 'mock method with frame option' => sub {
    my $mock = Test::MonkeyMock->new();
    $mock->mock(foo => sub { 'bar' }, frame => 0);
    $mock->mock(foo => sub { 'qux' }, frame => 2);
    $mock->mock(foo => sub { 'else' });

    is($mock->foo, 'bar');
    is($mock->foo, 'else');
    is($mock->foo, 'qux');
    is($mock->foo, 'else');
};

subtest 'return zero when no calls' => sub {
    my $mock = Test::MonkeyMock->new();
    $mock->mock(foo => sub { 'bar' });

    is($mock->mocked_called('foo'), 0);
};

subtest 'remember how many times method was called' => sub {
    my $mock = Test::MonkeyMock->new();
    $mock->mock(foo => sub { 'bar' });

    $mock->foo;
    $mock->foo;
    $mock->foo;

    is($mock->mocked_called('foo'), 3);
};

subtest 'remember the call stack' => sub {
    my $mock = Test::MonkeyMock->new();
    $mock->mock(foo => sub { 'bar' });

    $mock->foo;
    $mock->foo(1);
    $mock->foo('Hi there!');

    is_deeply([$mock->mocked_call_args('foo', 0)], []);
    is_deeply([$mock->mocked_call_args('foo', 1)], [1]);
    is_deeply([$mock->mocked_call_args('foo', 2)], ['Hi there!']);
};

subtest 'remember the return stack' => sub {
    my $mock = Test::MonkeyMock->new();

    my @returns = (qw/bar baz qux/);
    $mock->mock(foo => sub { shift @returns });

    $mock->foo;
    $mock->foo;
    $mock->foo;

    is_deeply([$mock->mocked_return_args('foo', 0)], ['bar']);
    is_deeply([$mock->mocked_return_args('foo', 1)], ['baz']);
    is_deeply([$mock->mocked_return_args('foo', 2)], ['qux']);
};

subtest 'return sub ref on can' => sub {
    my $mock = Test::MonkeyMock->new();
    $mock->mock(foo => sub { });

    ok(ref $mock->can('foo') eq 'CODE');
};

subtest 'correctly builds class name' => sub {
    my $mock = Test::MonkeyMock->new();
    $mock->mock(foo => sub { });
    $mock->mock(bar => sub { });
    $mock->mock(baz => sub { });
    $mock->mock(daz => sub { });

    like ref($mock), qr/Test::MonkeyMock::\d/;
};

subtest 'throw on unknown frame' => sub {
    my $mock = Test::MonkeyMock->new();
    $mock->mock(foo => sub { 'bar' });

    $mock->foo;

    like(exception { $mock->mocked_call_args('foo', 1) },
        qr/Unknown frame '1'/);
};

subtest 'throw on unmocked method when counting calls' => sub {
    my $mock = Test::MonkeyMock->new();

    like(exception { $mock->mocked_called('foo') }, qr/Unmocked method 'foo'/);
};

subtest 'throw on unmocked method when getting stack' => sub {
    my $mock = Test::MonkeyMock->new();

    like(exception { $mock->mocked_call_args('foo') },
        qr/Unmocked method 'foo'/);
};

subtest 'throw on unmocked method' => sub {
    my $mock = Test::MonkeyMock->new();

    like(exception { $mock->foo }, qr/Unmocked method 'foo'/);
};

subtest 'mock method with aliasing' => sub {
    my $mock = Test::MonkeyMock->new();
    $mock->mock(foo => sub { $_[1] = '123' });

    $mock->foo(my $bar);

    is $bar, '123';
};

done_testing;
