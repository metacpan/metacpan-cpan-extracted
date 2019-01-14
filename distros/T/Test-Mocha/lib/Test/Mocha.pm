package Test::Mocha;
# ABSTRACT: Test double framework with method stubs and behaviour verification
$Test::Mocha::VERSION = '0.65';

use strict;
use warnings;

use Carp 'croak';
use Exporter 'import';
use Scalar::Util 'blessed';
use Test::Mocha::CalledOk::Times;
use Test::Mocha::CalledOk::AtLeast;
use Test::Mocha::CalledOk::AtMost;
use Test::Mocha::CalledOk::Between;
use Test::Mocha::Mock;
use Test::Mocha::Spy;
use Test::Mocha::Types 'NumRange';
use Test::Mocha::Util 'extract_method_name';
use Types::Standard qw( ArrayRef HashRef Num slurpy );

our @EXPORT = qw(
  mock
  spy
  class_mock
  stub
  returns
  throws
  executes
  called_ok
  times
  atleast
  atmost
  between
  verify
  inspect
  inspect_all
  clear
  SlurpyArray
  SlurpyHash
);

# croak() messages should not trace back to Mocha modules
$Carp::Internal{$_}++ foreach qw(
  Test::Mocha
  Test::Mocha::CalledOk
  Test::Mocha::MethodStub
  Test::Mocha::Mock
  Test::Mocha::Spy
  Test::Mocha::Util
);

sub mock {
    return Test::Mocha::Mock->__new(@_);
}

sub spy ($) {
    return Test::Mocha::Spy->__new(@_);
}

sub stub (&@) {
    my ( $coderef, @responses ) = @_;

    foreach (@responses) {
        croak 'stub() responses should be supplied using ',
          'returns(), throws() or executes()'
          if ref ne 'CODE';
    }

    my @method_calls =
      Test::Mocha::Mock->__capture_method_calls( $coderef, 'stub' );
    for my $method_call (@method_calls) {
        # add stub to mock
        unshift @{ $method_call->invocant->__stubs->{ $method_call->name } },
          $method_call;

        # add response to stub
        Test::Mocha::MethodStub->cast($method_call);
        push @{ $method_call->__responses }, @responses;
    }
    return;
}

sub returns (@) {
    my (@return_values) = @_;
    return sub { $return_values[0] }
      if @return_values == 1;
    return sub { @return_values }
      if @return_values > 1;
    return sub { };  # if @return_values == 0
}

sub throws (@) {
    my (@exception) = @_;

    # check if first arg is a throwable exception
    return sub { $exception[0]->throw }
      if blessed( $exception[0] ) && $exception[0]->can('throw');

    return sub { croak @exception };

}

sub executes (&) {
    my ($callback) = @_;
    return $callback;
}

## no critic (RequireArgUnpacking,ProhibitMagicNumbers)
sub called_ok (&;@) {
    my $coderef = shift;

    my $called_ok;
    my $test_name;
    if ( @_ > 0 && ref $_[0] eq 'CODE' ) {
        $called_ok = shift;
    }
    if ( @_ > 0 ) {
        $test_name = shift;
    }

    my @method_calls =
      Test::Mocha::Mock->__capture_method_calls( $coderef, 'verify' );

    ## no critic (ProhibitAmpersandSigils)
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    $called_ok ||= &times(1);  # default if no times() is specified
    $called_ok->( $_, $test_name ) for @method_calls;
    return;
}
## use critic

## no critic (ProhibitBuiltinHomonyms)
sub times ($) {
    my ($n) = @_;
    croak 'times() must be given a number'
      unless Num->check($n);

    return sub {
        my ( $method_call, $test_name ) = @_;
        Test::Mocha::CalledOk::Times->test( $method_call, $n, $test_name );
    };
}
## use critic

sub atleast ($) {
    my ($n) = @_;
    croak 'atleast() must be given a number'
      unless Num->check($n);

    return sub {
        my ( $method_call, $test_name ) = @_;
        Test::Mocha::CalledOk::AtLeast->test( $method_call, $n, $test_name );
    };
}

sub atmost ($) {
    my ($n) = @_;
    croak 'atmost() must be given a number'
      unless Num->check($n);

    return sub {
        my ( $method_call, $test_name ) = @_;
        Test::Mocha::CalledOk::AtMost->test( $method_call, $n, $test_name );
    };
}

sub between ($$) {
    my ( $lower, $upper ) = @_;
    croak 'between() must be given 2 numbers in ascending order'
      unless NumRange->check( [ $lower, $upper ] );

    return sub {
        my ( $method_call, $test_name ) = @_;
        Test::Mocha::CalledOk::Between->test( $method_call, [ $lower, $upper ],
            $test_name );
    };
}

sub inspect (&) {
    my ($coderef) = @_;
    my @method_calls =
      Test::Mocha::Mock->__capture_method_calls( $coderef, 'inspect' );

    my @inspect;
    foreach my $method_call (@method_calls) {
        push @inspect,
          grep { $method_call->__satisfied_by($_) }
          @{ $method_call->invocant->__calls };
    }
    return @inspect;
}

sub inspect_all ($) {
    my ($mock) = @_;

    croak 'inspect_all() must be given a mock or spy object'
      if !$mock->isa('Test::Mocha::SpyBase');

    return @{ $mock->{calls} };
}

sub clear (@) {
    my @mocks = @_;

    croak 'clear() must be given mock or spy objects'
      if @mocks == 0;
    croak 'clear() accepts mock and spy objects only'
      if 0 < ( grep { !ref $_ || !$_->isa('Test::Mocha::SpyBase') } @mocks );

    @{ $_->__calls } = () foreach @mocks;

    return;
}

## no critic (NamingConventions::Capitalization)
sub SlurpyArray () {
    # uncoverable pod
    return slurpy(ArrayRef);
}

sub SlurpyHash () {
    # uncoverable pod
    return slurpy(HashRef);
}
## use critic

sub class_mock {
    my ($mocked_class) = @_;

    my $module_file = join( q{/}, split q{::}, $mocked_class ) . '.pm';
    my $caller_pkg = caller;
    no strict 'refs';  ## no critic (TestingAndDebugging::ProhibitNoStrict)

    # make sure the real module is not already loaded
    croak "Package '$mocked_class' is already loaded so it cannot be mocked"
      if defined ${ $caller_pkg . '::INC' }{$module_file};

    # check if package has already been mocked
    croak "Package '$mocked_class' is already mocked"
      if defined *{ $mocked_class . '::AUTOLOAD' }{CODE};

    my $mock = mock($mocked_class);

    *{ $mocked_class . '::AUTOLOAD' } = sub {
        my ($method) = extract_method_name( our $AUTOLOAD );
        $mock->$method(@_);
    };
    return $mock;
}

1;

__END__

=pod

=head1 NAME

Test::Mocha - Test double framework with method stubs and behaviour verification

=for html
<a href="https://travis-ci.org/stevenl/Test-Mocha"><img src="https://travis-ci.org/stevenl/Test-Mocha.svg?branch=master" alt="Build Status"></a>
<a href='https://coveralls.io/r/stevenl/Test-Mocha?branch=master'><img src='https://coveralls.io/repos/stevenl/Test-Mocha/badge.png?branch=master' alt='Coverage Status' /></a>

=head1 VERSION

version 0.65

=head1 SYNOPSIS

Test::Mocha is a test double framework for testing code that has dependencies
on other objects.

    use Test::More tests => 2;
    use Test::Mocha;
    use Types::Standard qw( Int );

    # create the mock
    my $warehouse = mock;

    # stub method calls (with type constraint for matching argument)
    stub { $warehouse->has_inventory($item1, Int) } returns 1;

    # execute the code under test
    my $order = Order->new(item => $item1, quantity => 50);
    $order->fill($warehouse);

    # verify interactions with the dependent object
    ok $order->is_filled, 'Order is filled';
    called_ok { $warehouse->remove_inventory($item1, 50) } '... and inventory is removed';

    # clear the invocation history
    clear $warehouse;

=head1 DESCRIPTION

Test::Mocha is a test double framework inspired by Java's Mockito.
It offers a different approach to other mocking frameworks in that instead
of setting up the expected behaviour beforehand you ask questions about
interactions after execution of the system-under-test. This approach means
there is less setup needed to use your test double which means you can
focus more on testing, and it minimises the coupling of the tests to the
implementation which means less maintenance of your test code.

Explicit stubbing is only required when the dependent object is expected to
return a specific response. And you can even use argument matchers to skip
having to enter the exact method arguments for the stub.

After executing the code under test, you can test that your code is interacting
correctly with its dependent objects. Selectively verify the method calls that
you are interested in only. As you verify behaviour, you focus on external
interfaces rather than on internal state.

=head1 FUNCTIONS

=head2 mock

    $mock = mock;

C<mock()> creates a new mock object. It's that quick and simple!
It is ready out-of-the-box to pretend to be any object you want it to be
and to accept any method calls on it.

Any public method may be called on mocks. By default the methods will return
C<undef> or C<()> depending on the context. See L</"stub"> below for how to
change this behaviour.

    $result = $mock->method(@args); # returns undef
    @result = $mock->method(@args); # returns ()

C<isa()>, C<does()> or C<DOES()> returns true for any class or role name.
C<can()> returns a reference to the default public method. This is
particularly handy when the dependent object needs to satisfy attribute
type constraint checks with OO frameworks such as L<Moose>.

    $mock->isa('AnyClass');     # returns 1
    $mock->does('AnyRole');     # returns 1
    $mock->DOES('AnyRole');     # returns 1
    $mock->can('any_method');   # returns a coderef

C<ref()> is a special method that you can stub to specify the value you would
like returned when you use the C<ref()> function with a mock object.

    stub { $mock->ref } returns 'SomeClass';
    print ref($mock); # prints 'SomeClass'

=head2 spy

    $spy = spy($object);

Don't want to abstract away the behaviour of an entire class? Use a spy.
Spies act as wrappers to real objects. Rather than giving pretend responses
as mocks do, they delegate the method calls to the real objects (including
the UNIVERSAL methods like C<isa()> and C<DOES>) and return their actual
responses. But the method calls can also be verified using L</"called_ok">
or overridden using L</"stub">.

This means you can use the existing behaviour of the object and fake only
parts of it, such as a call to a server that's not available in your dev
environment or that returns non-deterministic results.

=head2 stub

    stub { $mock->method(@args) } returns(@values)
    stub { $mock->method(@args) } throws($exception)
    stub { $mock->method(@args) } executes($coderef)

By default, the mock object already acts as a stub that accepts any method
call and returns C<undef> or C<()>. However, you can use C<stub()> to tell a
method to give an alternative response. You can specify 3 types of responses:

=over 4

=item C<returns(@values)>

Specifies that a stub should return 1 or more values.

    stub { $mock->method(@args) } returns 1, 2, 3;
    print $mock->method(@args);  # prints "123"

=item C<throws($message)>

Specifies that a stub should raise an exception.

    stub { $mock->method(@args) } throws 'an error';
    $mock->method(@args);  # croaks with "an error at test.t line 10."

=item C<executes($coderef)>

Specifies that a stub should execute the given callback. The arguments used
in the method call are passed on to the callback.

    my @returns = qw( first second third );

    stub { $list->get(Int) } executes {
        my ( $self, $i ) = @_;
        die "index out of bounds" if $i < 0;
        return $returns[$i];
    };

    print $list->get(0);   # prints "first"
    print $list->get(1);   # prints "second"
    print $list->get(5);   # warns "Use of uninitialized value in print at test.t line 16."
    print $list->get(-1);  # dies with "Index out of bounds at test.t line 10."

=back

A stub applies to the exact mock, method and arguments specified (but see also
L</"ARGUMENT MATCHING"> for a shortcut around this).

    stub { $list->get(0) } returns 'first';
    stub { $list->get(1) } returns 'second';

    print $list->get(0);  # prints "first"
    print $list->get(1);  # prints "second"
    print $list->get(2);  # nothing printed (since default stub returns an empty list)

Chain responses together to provide a consecutive series.

    stub { $iterator->next }
      returns(1), returns(2), returns(3), throws('exhausted');

    print $iterator->next;  # prints "1"
    print $iterator->next;  # prints "2"
    print $iterator->next;  # prints "3"
    print $iterator->next;  # croaks with "exhausted at test.t line 13."

The last stubbed response will persist until it is overridden.

    stub { $warehouse->has_inventory($item, 10) } returns 1;
    print( $warehouse->has_inventory($item, 10) ) for 1 .. 5; # prints "11111"

    stub { $warehouse->has_inventory($item, 10) } returns '';
    print( $warehouse->has_inventory($item, 10) ) for 1 .. 5; # nothing printed

You can apply a stub to multiple method calls in one go to set them with the
same responses.

    stub {
        $mock1->method1(1);
        $mock2->method2(1);
        $spy->method3(2);
    } returns(2), returns(1);

=head2 called_ok

    called_ok { $mock->method(@args) }
    called_ok { $mock->method(@args) } times($n)
    called_ok { $mock->method(@args) } atleast($n)
    called_ok { $mock->method(@args) } atmost($n)
    called_ok { $mock->method(@args) } between($m, $n)
    called_ok { $mock->method(@args) } $test_name

C<called_ok()> is used to test the interactions with the mock object. You can
use it to verify that the correct method was called, with the correct set of
arguments, and the correct number of times. C<called_ok()> plays nicely with
L<Test::Simple> and Co - it will print the test result along with your other
tests and you must count calls to C<called_ok()> in your test plans.

    called_ok { $warehouse->remove($item, 50) };
    # prints "ok 1 - remove("book", 50) was called 1 time(s)"

The following functions are available to verify the number of calls:

=over 4

=item C<times>

Specifies the number of times the given method is expected to be called.
C<times(1)> is the default if no option is specified.

    called_ok { $mock->method(@args) } times(3);
    # prints "ok 1 - method(@args) was called 3 time(s)"

Note: C<times()> may clash with the built-in function with the same name.
You may explicitly specify which one you want by qualifying it as
C<&times(3)> or C<CORE::times>.

=item C<atleast>

Specifies the minimum number of times the given method is expected to be
called.

    called_ok { $mock->method(@args) } atleast(3);
    # prints "ok 1 - method(@args) was called at least 3 time(s)"

=item C<atmost>

Specifies the maximum number of times the given method is expected to be
called.

    called_ok { $mock->method(@args) } atmost(5);
    # prints "ok 1 - method(@args) was called at most 5 time(s)"

=item C<between>

Specifies the minimum and maximum number of times the given method is
expected to be called.

    called_ok { $mock->method(@args) } between(3, 5);
    # prints "ok 1 - method(@args) was called between 3 and 5 time(s)"

=back

An optional last argument C<$test_name> may be specified to be printed instead
of the default.

    called_ok { $warehouse->remove_inventory($item, 50) } 'inventory removed';
    # prints "ok 1 - inventory removed"

    called_ok { $warehouse->remove_inventory($item, 50) } times(0), 'inventory not removed';
    # prints "ok 2 - inventory not removed"

You can verify multiple method calls in one go.

    called_ok {
        $mock1->method1(1);
        $mock2->method2(1);
        $spy->method3(2);
    } times(2);

=head2 inspect

    @method_calls = inspect { $mock->method(@args) };

    ($method_call) = inspect { $warehouse->remove_inventory(Str, Int) };
    $method_call->name;           # "remove_inventory"
    $method_call->args;           # ("book", 50)
    $method_call->caller;         # ("test.pl", 5)
    $method_call->stringify;      # 'remove_inventory("book", 50)'
    $method_call->stringify_long; # 'remove_inventory("book", 50) called at test.pl line 5'

C<inspect()> returns a list of method call objects that match the given method
call specification. It is used to inspect the methods that have been called on
the mock object. It can be useful for debugging failed C<called_ok()> calls.
Or use it in place of a complex call to C<called_ok()> to break it down in
smaller tests.

The method call objects have the following accessor methods:

=over 4

=item *

C<name> - The name of the method called.

=item *

C<args> - The list of arguments passed to the method call.

=item *

C<caller> - The file and line number from which the method was called.

=item *

C<stringify> - The name and arguments as a string.

=item *

C<stringify_long> - The name, arguments, file and line number as a string.`

=back

They are also string overloaded with the value from C<stringify>.

=head2 inspect_all

    @all_method_calls = inspect_all $mock

C<inspect_all()> returns a list of all methods called on the mock object.
This is mainly used for debugging.

=head2 clear

    clear $mock1, $mock2, ...

Clears the method call history for one or more mocks so that they can be
reused in another test. Note that this does not clear the methods that have
been stubbed.

=head1 ARGUMENT MATCHING

Argument matchers may be used in place of specifying exact method arguments.
They allow you to be more general and will save you much time in your
method specifications to stubs and verifications. Argument matchers may be used
with C<stub()>, C<called_ok()> and C<inspect>.

=head2 Pre-defined types

You may use any of the ready-made types in L<Types::Standard>. (Alternatively,
Moose types like those in L<MooseX::Types::Moose> and
L<MooseX::Types::Structured> will also work.)

    use Types::Standard qw( Any );

    my $mock = mock;
    stub { $mock->foo(Any) } returns 'ok';

    print $mock->foo(1);        # prints: ok
    print $mock->foo('string'); # prints: ok

    called_ok { $mock->foo(Defined) } times(2);
    # prints: ok 1 - foo(Defined) was called 2 time(s)

You may use the normal features of the types: parameterized and structured
types, and type unions, intersections and negations (but there's no need to
use coercions).

    use Types::Standard qw( Any ArrayRef HashRef Int StrMatch );

    my $list = mock;
    $list->set(1, [1,2]);
    $list->set(0, 'foobar');

    # parameterized type
    # prints: ok 1 - set(Int, StrMatch[(?^:^foo)]) was called 1 time(s)
    called_ok { $list->set( Int, StrMatch[qr/^foo/] ) };

=head2 Self-defined types

You may also use your own types, defined using L<Type::Utils>.

    use Type::Utils -all;

    # naming the type means it will be printed nicely in called_ok()'s output
    my $positive_int = declare 'PositiveInt', as Int, where { $_ > 0 };

    # prints: ok 2 - set(PositiveInt, Any) was called 1 time(s)
    called_ok { $list->set($positive_int, Any) };

=head2 Argument slurping

C<SlurpyArray> and C<SlurpyHash> are special argument matchers exported by
Test::Mocha that you can use when you don't care what arguments are used.
They will just slurp up the remaining arguments as though they match.

    called_ok { $list->set(SlurpyArray) };
    called_ok { $list->set(Int, SlurpyHash) };

Because they consume the remaining arguments, you can't use further argument
validators after them. But you can, of course, use them before. Note also that
they will match empty argument lists.

=for Pod::Coverage SlurpyArray SlurpyHash

=head1 MOCKING CLASS METHODS (experimental)

=head2 class_mock

C<class_mock()> creates a mock for stubbing class methods and module functions.

    class_mock 'Some::Class';

To stub a class method or module function:

    stub { Some::Class->some_class_method() } returns 'something';
    is( Some::Class->some_class_method(), 'something' );

    stub { Some::Class::some_module_function() } returns 'something';
    is( Some::Class::some_module_function(), "something" );

Validation is handled similarly.

    called_ok { Some::Class->some_class_method() } "some_class_method called";
    called_ok { Some::Class::some_module_function() } "some_module_function called";

Note: The original class that you mock must not be imported before you have
finished stubbing the class. This means that if your module under test C<use>s
it, then you must C<use_ok> or C<require> the test module after stubbing the
mock class.

Also note: Currently you cannot stub new().

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-test-mocha at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=Test-Mocha>. You will be automatically notified of any
progress on the request by the system.

=head1 AUTHOR

Steven Lee <stevenwh.lee@gmail.com>

=head1 ACKNOWLEDGEMENTS

This module is a fork from L<Test::Magpie> originally written by Oliver
Charles (CYCLES).

It is inspired by the popular L<Mockito|http://code.google.com/p/mockito/>
for Java and Python by Szczepan Faber.

It is not associated with the Javascript test framework for node.js called
Mocha. I named Test::Mocha before that came about.

Thanks to the following people who have contributed to Test::Mocha:

=over

Scott Davis for adding the C<class_mock()> function.

Chad Granum <exodist@cpan.org>

Bob Showalter <showaltb@gmail.com>

=back

=head1 SEE ALSO

L<Test::MockObject>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Steven Lee.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTY

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=cut
