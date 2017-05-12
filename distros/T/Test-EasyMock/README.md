# NAME

Test::EasyMock - A mock library which is usable easily.

# SYNOPSIS

    use Test::EasyMock qw(
        create_mock
        expect
        replay
        verify
        reset
    );
    

    my $mock = create_mock();
    expect($mock->foo(1))->and_scalar_return('a');
    expect($mock->foo(2))->and_scalar_return('b');
    replay($mock);
    $mock->foo(1); # return 'a'
    $mock->foo(2); # return 'b'
    $mock->foo(3); # Unexpected method call.(A test is failed)
    verify($mock); # verify all expectations is invoked.
    

    reset($mock);
    expect($mock->foo(1, 2)->and_array_return('a', 'b');
    expect($mock->foo({ value => 3 })->and_array_return('c');
    replay($mock);
    $mock->foo(1, 2); # return ('a', 'b')
    $mock->foo({ value => 3 }); # return ('c')
    verify($mock);
    

    reset($mock);
    expect($mock->foo(1))->and_scalar_return('a');
    expect($mock->foo(1))->and_scalar_return('b');
    replay($mock);
    $mock->foo(1); # return 'a'
    $mock->foo(1); # return 'b'
    $mock->foo(1); # Unexpected method call.(A test is failed)
    verify($mock);

Using `Test::Deep`'s special comparisons.

    use Test::EasyMock qw(
        create_mock
        expect
        replay
        verify
        reset
        whole
    );
    use Test::Deep qw(
        ignore
    );
    

    my $mock = create_mock();
    expect($mock->foo(1, ignore())->and_scalar_return('a');
    expect($mock->foo({ value => 1, random => ignore() })->and_scalar_return('b');
    replay($mock);
    $mock->foo(1, 1234); # return 'a'
    $mock->foo({ value => 1, random => 1234 }); # return 'b'
    verify($mock);
    

    reset($mock);
    expect($mock->foo(whole(ignore())))->and_stub_scalar_return('a');
    replay($mock);
    $mock->foo(); # return 'a'
    $mock->foo(1, 2, 3); # return 'a'
    $mock->foo({ arg1 => 1, arg2 => 2 }); # return 'a'
    verify($mock);

Mock to class method.

    use Test::EasyMock qw(
        expect
        replay
        verify
    );
    use Test::EasyMock::Class qw(
        create_class_mock
    );
    

    my $mock = create_class_mock('Foo::Bar');
    expect($mock->foo(1))->and_scalar_return('a');
    replay($mock);
    Foo::Bar->foo(1); # return 'a'
    Foo::Bar->foo(2); # Unexpected method call.(A test is failed)
    verify($mock); # verify all expectations is invoked.

# DESCRIPTION

This is mock library modeled on 'EasyMock' in Java.

# FUNCTIONS

## create\_mock(\[$module\_name|$object\])

Creates a mock object.
If specified the _$module\_name_ then a _isa($module\_name)_ method of the mock object returns true.

## expect(<a mock method call>)

Record a method invocation and behavior.

The following example is expecting the _foo_ method invocation with _$arguments_
and a result of the invocation is _123_.

    expect($mock->foo($arguments))
        ->and_scalar_return(123);

And the next example is expecting the _foo_ method invocation without an argument
and a result of the invocation is _(1, 2, 3)_.

    expect($mock->foo())
        ->and_array_return(1, 2, 3);

### A list of _and\_\*_ methods.

- and\_scalar\_return($value)

    Add scalar result to the expectation.

- and\_array\_return(@values)

    Add array result to the expectation.

- and\_list\_return(@values)

    Add list result to the expectation.

- and\_answer($code)

    Add code to the expectation, it calculate an answer.

- and\_die(\[$message\])

    Add _die_ behavior to the expectation.

- and\_stub\_scalar\_return($value)

    Set scalar result as a stub to the expectation.

- and\_stub\_array\_return(@values)

    Set array result as a stub to the expectation.

- and\_stub\_list\_return(@values)

    Set list result as a stub to the expectation.

- and\_stub\_answer($code)

    Add code as a stub to the expectation, it calculate an answer.

- and\_stub\_die(\[$message\])

    Set _die_ behavior as as stub to the expectation.

## replay($mock \[, $mock2 ...\])

Replay the mock object behaviors which is recorded by the _expect_ function.

    replay($mock);

## verify($mock)

Verify the mock method invocations.

## reset($mock)

Reset the mock.

## whole($arguments)

It is a kind of an argument matcher.
The matcher considers that the whole argument is array ref.

    # same as `expect($mock->foo(1, 2))`
    expect($mock->foo( whole([1, 2]) ));
    

    # matches any arguments. (eg. foo(), foo(1,2), foo({}), etc...)
    expect($mock->foo( whole(ignore()) ));

# AUTHOR

keita iseki `<keita.iseki+cpan at gmail.com>`

# LICENCE AND COPYRIGHT

Copyright (c) 2012, keita iseki `<keita.iseki+cpan at gmail.com>`. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See [perlartistic](http://search.cpan.org/perldoc?perlartistic).

# SEE ALSO

- EasyMock

    [http://easymock.org/](http://easymock.org/)

    It is a very wonderful library for the Java of a mock object.

- Test::Deep

    [http://search.cpan.org/~rjbs/Test-Deep-0.110/lib/Test/Deep.pm](http://search.cpan.org/~rjbs/Test-Deep-0.110/lib/Test/Deep.pm)

- Test::EasyMock::Class

    [http://search.cpan.org/~kiseki/Test-EasyMock/lib/Test/EasyMock/Class.pm](http://search.cpan.org/~kiseki/Test-EasyMock/lib/Test/EasyMock/Class.pm)
