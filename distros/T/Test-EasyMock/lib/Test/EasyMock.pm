package Test::EasyMock;
use strict;
use warnings;
use version; our $VERSION = '0.10';

=head1 NAME

Test::EasyMock - A mock library which is usable easily.

=head1 SYNOPSIS

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

Using C<Test::Deep>'s special comparisons.

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

=head1 DESCRIPTION

This is mock library modeled on 'EasyMock' in Java.

=cut
use Carp qw(confess);
use Exporter qw(import);
use Scalar::Util qw(blessed);
use Test::EasyMock::ArgumentsMatcher;
use Test::EasyMock::MockControl;

our @EXPORT_OK = qw(
    create_mock
    expect
    replay
    reset
    verify
    whole
);
our %EXPORT_TAGS = (all => [@EXPORT_OK]);

=head1 FUNCTIONS

=head2 create_mock([$module_name|$object])

Creates a mock object.
If specified the I<$module_name> then a I<isa($module_name)> method of the mock object returns true.

=cut
sub create_mock {
    my $control = Test::EasyMock::MockControl->create_control(@_);
    return $control->create_mock;
}

=head2 expect(<a mock method call>)

Record a method invocation and behavior.

The following example is expecting the I<foo> method invocation with I<$arguments>
and a result of the invocation is I<123>.

    expect($mock->foo($arguments))
        ->and_scalar_return(123);

And the next example is expecting the I<foo> method invocation without an argument
and a result of the invocation is I<(1, 2, 3)>.

    expect($mock->foo())
        ->and_array_return(1, 2, 3);

=head3 A list of I<and_*> methods.

=over

=item and_scalar_return($value)

Add scalar result to the expectation.

=item and_array_return(@values)

Add array result to the expectation.

=item and_list_return(@values)

Add list result to the expectation.

=item and_answer($code)

Add code to the expectation, it calculate an answer.

=item and_die([$message])

Add I<die> behavior to the expectation.

=item and_stub_scalar_return($value)

Set scalar result as a stub to the expectation.

=item and_stub_array_return(@values)

Set array result as a stub to the expectation.

=item and_stub_list_return(@values)

Set list result as a stub to the expectation.

=item and_stub_answer($code)

Add code as a stub to the expectation, it calculate an answer.

=item and_stub_die([$message])

Set I<die> behavior as as stub to the expectation.

=back

=cut
sub expect {
    return __delegate(expect => @_);
}

=head2 replay($mock [, $mock2 ...])

Replay the mock object behaviors which is recorded by the I<expect> function.

    replay($mock);

=cut
sub replay {
    __delegate(replay => $_) for @_;
}

=head2 verify($mock)

Verify the mock method invocations.

=cut
sub verify {
    __delegate(verify => $_) for @_;
}

=head2 reset($mock)

Reset the mock.

=cut
sub reset {
    __delegate(reset => $_) for @_;
}

=head2 whole($arguments)

It is a kind of an argument matcher.
The matcher considers that the whole argument is array ref.

  # same as `expect($mock->foo(1, 2))`
  expect($mock->foo( whole([1, 2]) ));
  
  # matches any arguments. (eg. foo(), foo(1,2), foo({}), etc...)
  expect($mock->foo( whole(ignore()) ));

=cut
sub whole {
    my ($args) = @_;
    return Test::EasyMock::ArgumentsMatcher->new($args);
}

sub __delegate {
    my ($method, $mock, @args) = @_;
    my $control = __control_of($mock)
        or confess('Speocified mock is not under management');
    return $control->$method($mock, @args);
}

sub __control_of {
    my ($mock) = @_;
    my $class = blessed $mock;
    return unless $class && $class eq 'Test::EasyMock::MockObject';
    return $mock->{_control};
}

1;
__END__

=head1 AUTHOR

keita iseki C<< <keita.iseki+cpan at gmail.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2012, keita iseki C<< <keita.iseki+cpan at gmail.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 SEE ALSO

=over

=item EasyMock

L<http://easymock.org/>

It is a very wonderful library for the Java of a mock object.

=item Test::Deep

L<http://search.cpan.org/~rjbs/Test-Deep-0.110/lib/Test/Deep.pm>

=item Test::EasyMock::Class

L<http://search.cpan.org/~kiseki/Test-EasyMock/lib/Test/EasyMock/Class.pm>

=back

=cut
