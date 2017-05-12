# NAME

Test::MonkeyMock - Usable mock class

# SYNOPSIS

    # Create a new mock object
    my $mock = Test::MonkeyMock->new;
    $mock->mock(foo => sub { 'bar' });
    $mock->foo;

    # Mock method when number of arguments is even
    $mock->mock(foo => sub { }, when => sub { @_ == 2 });

    # Mock method when it's called only the first time
    $mock->mock(foo => sub { }, frame => 0);

    # Mock existing object
    my $mock = Test::MonkeyMock->new(MyObject->new());
    $mock->mock(foo => sub { 'bar' });
    $mock->foo;

    # Check how many times the method was called
    my $count = $mock->mocked_called('foo');

    # Check what arguments were passed on the first call
    my @args = $mock->mocked_call_args('foo');

    # Check what arguments were passed on the second call
    my @args = $mock->mocked_call_args('foo', 1);

    # Get all the stack
    my $call_stack = $mock->mocked_call_stack('foo');

# DESCRIPTION

Why? I used and still use [Test::MockObject](https://metacpan.org/pod/Test::MockObject) and [Test::MockObject::Extends](https://metacpan.org/pod/Test::MockObject::Extends)
a lot but sometimes it behaves very strangely introducing hard to find global
bugs in the test code, which is very painful, since the test suite should have
as least bugs as possible. [Test::MonkeyMock](https://metacpan.org/pod/Test::MonkeyMock) is somewhat a subset of
[Test::MockObject](https://metacpan.org/pod/Test::MockObject) but without side effects.

[Test::MonkeyMock](https://metacpan.org/pod/Test::MonkeyMock) is also very strict. When mocking a new object:

- throw when using `mocked_called` on unmocked method
- throw when using `mocked_call_args` on unmocked method

When mocking an existing object:

- throw when using `mock` on unknown method
- throw when using `mocked_called` on unknown method
- throw when using `mocked_call_args` on unknown method

# METHODS

## `new`

Creates new mock or extends an existing object.

    Test::MonkeyMock->new;
    Test::MonkeyMock->new($object);

## `can($method)`

Returns what a real `can` does.

## `mock($method, $code, %options)`

Mocks method with a subroutine.

Options are conditions that are checked when dispatching a method. If the
condition fails the next candidate is taken.

### `when`

When is called with original `@_`. Thus you can check for specific parameteres.

    my $mock = Test::MonkeyMock->new();
    $mock->mock(foo => sub { 'bar' }, when => sub { @_ == 2 });
    $mock->mock(foo => sub { 'else' });

    is $mock->foo(1), 'bar';
    is $mock->foo, 'else';

### `frame`

Checks how many times the mocked method was called.

    my $mock = Test::MonkeyMock->new();
    $mock->mock(foo => sub { 'bar' }, frame => 0);
    $mock->mock(foo => sub { 'qux' }, frame => 2);
    $mock->mock(foo => sub { 'else' });

    is $mock->foo, 'bar';
    is $mock->foo, 'else';
    is $mock->foo, 'qux';
    is $mock->foo, 'else';

## `mocked_call_args($method, $frame)`

Returns the arguments during method call. With `$frame` you can access the call
stack.

## `mocked_call_stack($method)`

Returns the complete call stack of the method.

## `mocked_called($method)`

Returns how many times the method was called.

## `mocked_return_args($method, $frame)`

Returns the return value of the method. With `$frame` you can access the call
stack.

## `mocked_return_stack($method)`

Returns the complete return stack of the method.

# AUTHOR

Viacheslav Tykhanovskyi, `viacheslav.t@gmail.com`

# COPYRIGHT AND LICENSE

Copyright (C) 2012-2014, Viacheslav Tykhanovskyi

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

This program is distributed in the hope that it will be useful, but without any
warranty; without even the implied warranty of merchantability or fitness for
a particular purpose.
