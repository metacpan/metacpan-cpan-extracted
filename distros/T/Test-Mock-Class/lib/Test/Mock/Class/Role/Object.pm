#!/usr/bin/perl -c

package Test::Mock::Class::Role::Object;

=head1 NAME

Test::Mock::Class::Role::Object - Role for base object of mock class

=head1 DESCRIPTION

This role provides an API for defining and changing behavior of mock class.

=cut

use 5.006;

use strict;
use warnings;

our $VERSION = '0.0303';

use Moose::Role;


use Symbol ();

use Test::Assert ':all';


## no critic qw(ProhibitConstantPragma)
use constant Exception => 'Test::Mock::Class::Exception';
use English '-no_match_vars';

use Exception::Base (
    Exception,
    'Exception::Fatal',
    '+ignore_package' => [__PACKAGE__],
);


=head1 ATTRIBUTES

=over

=item B<_mock_call> : HashRef

Count of method calls stored as HashRef.

=cut

has '_mock_call' => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { {} },
);


=item B<_mock_expectation> : HashRef

Expectations for mock methods stored as HashRef.

=cut

has '_mock_expectation' => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { {} },
);


=item B<_mock_action> : HashRef

Return values or actions for mock methods stored as HashRef.

=back

=cut

has '_mock_action' => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { {} },
);


use namespace::clean -except => 'meta';


## no critic qw(RequireCheckingReturnValueOfEval)

=head1 METHODS

=over

=item B<mock_tally>(I<>) : Self

Check the expectations at the end.  It should be called expicitly if
C<minimum> or C<count> parameter was used for expectation, or following
methods was called: C<mock_expect_at_least_once>,
C<mock_add_expectation_call_count>, C<mock_expect_minimum_call_count>
or C<mock_expect_once>.

=cut

sub mock_tally {
    my ($self) = @_;

    my $expectation = $self->_mock_expectation;

    return if not defined $expectation
              or (ref $expectation || '') ne 'HASH';

    foreach my $method (keys %{ $expectation }) {
        next if not defined $expectation->{$method}
                or (ref $expectation->{$method} || '') ne 'ARRAY';

        foreach my $rule (@{ $expectation->{$method} }) {
            if (defined $rule->{count}) {
                my $count = $rule->{call} || 0;
                fail([
                    'Expected call count (%d) for method (%s) with calls (%d)',
                    $rule->{count}, $method, $count
                ]) if ($count != $rule->{count});
            };
            if (defined $rule->{minimum}) {
                my $count = $rule->{call} || 0;
                fail([
                    'Minimum call count (%d) for method (%s) with calls (%d)',
                    $rule->{minimum}, $method, $count
                ]) if ($count < $rule->{minimum});
            };
        };
    };

    return $self;
};


=item B<mock_invoke>( I<method> : Str, I<args> : Array ) : Any

Increases the call counter and returns the expected value for the method name
and checks expectations.  Will generate any test assertions as a result of
expectations if there is a test present.

If more that one expectation matches, all of them are checked.  If one of them
fails, the whole C<mock_invoke> method is failed.

This method is called in overridden methods of mock class, but you need to
call it explicitly if you constructed own method.

=cut

sub mock_invoke {
    my ($self, $method, @args) = @_;

    assert_not_null($method) if ASSERT;

    my $timing = $self->_mock_add_call($method, @args);
    $self->_mock_check_expectations($method, $timing, @args);
    return $self->_mock_emulate_call($method, $timing, @args);
};


=item B<mock_return>( I<method> : Str, I<value> : Any, :I<at> : Int, :I<args> : ArrayRef[Any] ) : Self

Sets a return for a parameter list that will be passed on by call to this
method that match.

The first value is returned if more than one parameter list matches method's
arguments.  The C<undef> value is returned if none of parameters matches.

=over

=item method

Method name.

=item value

Returned value.

  $m->mock_return( 'open', 1 );

If value is coderef, then it is called with method name, current timing
and original arguments as arguments.  It allows to return array rather than
scalar.

  $m->mock_return( 'sequence', sub {
      qw( one two three )[ $_[1] ]
  } );
  $m->mock_return( 'get_array', sub { (1,2,3) } );

=item at

Value is returned only for current timing, started from C<0>.

  $m->mock_return( 'sequence', 'one',   at => 0 );
  $m->mock_return( 'sequence', 'two',   at => 1 );
  $m->mock_return( 'sequence', 'three', at => 2 );

=item args

Value is returned only if method is called with proper argument.

  $m->mock_return( 'get_value', 'admin', args => ['dbuser'] );
  $m->mock_return( 'get_value', 'secret', args => ['dbpass'] );
  $m->mock_return( 'get_value', sub { $_[2] }, args => [qr/.*/] );

=back

=cut

sub mock_return {
    my ($self, $method, $value, %params) = @_;

    $self->throw_error(
        'Usage: $mock->mock_return( METHOD => VALUE, PARAMS )'
    ) unless defined $method;

    assert_equals('HASH', ref $self->_mock_action) if ASSERT;
    push @{ $self->_mock_action->{$method} } => { %params, value => $value };

    return $self;
};


=item B<mock_return_at>( I<at> : Int, I<method> : Str, I<value> : Any, :I<args> : ArrayRef[Any] ) : Self

Convenience method for returning a value upon the method call.

=cut

sub mock_return_at {
    my ($self, $at, $method, $value, %params) = @_;

    $self->throw_error(
        message => 'Usage: $mock->mock_return_at( AT, METHOD => VALUE, PARAMS )'
    ) unless defined $at and defined $method;

    return $self->mock_return( $method => $value, %params, at => $at );
};


=item B<mock_throw>( I<method> : Str, :I<at> : Int, I<exception> : Str|Object, :I<args> : ArrayRef[Any], I<params> : Hash ) : Self

Sets up a trigger to throw an exception upon the method call.  The method
takes the same arguments as C<mock_return>.

If an I<exception> parameter is a string, the L<Exception::Assertion> is
thrown with this parameter as its message and rest of parameters as its
arguments.  If an I<exception> parameter is an object reference, the C<throw>
method is called on this object with predefined message and rest of parameters
as its arguments.

=cut

sub mock_throw {
    my ($self, $method, $exception, %params) = @_;

    Exception::Argument->throw(
        message => 'Usage: $mock->mock_throw( METHOD => EXCEPTION, PARAMS )'
    ) unless defined $method;

    $exception = Exception::Assertion->new(
        message => $exception,
        reason  => ['Thrown on method (%s)', $method],
        %params
    ) unless blessed $exception;

    assert_equals('HASH', ref $self->_mock_action) if ASSERT;
    push @{ $self->_mock_action->{$method} } => {
        %params,
        value => sub {
            $exception->throw;
        },
    };

    return $self;
};


=item B<mock_throw_at>( I<at> : Int, I<method> : Str, I<exception> : Str|Object, :I<args> : ArrayRef[Any] ) : Self

Convenience method for throwing an error upon the method call.

=cut

sub mock_throw_at {
    my ($self, $at, $method, $exception, %params) = @_;

    Exception::Argument->throw(
        message => 'Usage: $mock->mock_throw_at( AT, METHOD => EXCEPTION, PARAMS )'
    ) unless defined $at and defined $method;

    return $self->mock_throw( $method => $exception, %params, at => $at );
};


=item B<mock_expect>( I<method> : Str, :I<at> : Int, :I<minimum> : Int, :I<maximum> : Int, :I<count> : Int, :I<args> : ArrayRef[Any] ) : Self

Sets up an expected call with a set of expected parameters in that call.  Each
call will be compared to these expectations regardless of when the call is
made.  The method takes the same arguments as C<mock_return>.

=cut

sub mock_expect {
    my ($self, $method, %params) = @_;

    Exception::Argument->throw(
        message => 'Usage: $mock->mock_expect( METHOD => PARAMS )'
    ) unless defined $method;

    Exception->throw(
        message => ['Cannot set expected arguments as no method (%s) in class (%s)', $method, $self->meta->name],
    ) unless $self->meta->has_method($method);

    assert_equals('HASH', ref $self->_mock_expectation) if ASSERT;
    push @{ $self->_mock_expectation->{$method} } => {
        %params,
    };

    return $self;
};


=item B<mock_expect_at>( I<at> : Int, I<method> : Str, :I<args> : ArrayRef[Any] ) : Self

Sets up an expected call with a set of expected parameters in that call.

=cut

sub mock_expect_at {
    my ($self, $at, $method, %params) = @_;

    Exception::Argument->throw(
        message => 'Usage: $mock->mock_expect_at( AT, METHOD => PARAMS )'
    ) unless defined $at and defined $method;

    return $self->mock_expect( $method => %params, at => $at );
};


=item B<mock_expect_call_count>( I<method> : Str, I<count> : Int, :I<args> : ArrayRef[Any] ) : Self

Sets an expectation for the number of times a method will be called. The
C<mock_tally> method have to be used to check this.

=cut

sub mock_expect_call_count {
    my ($self, $method, $count, %params) = @_;

    Exception::Argument->throw(
        message => 'Usage: $mock->mock_expect_call_count( METHOD, COUNT => PARAMS )'
    ) unless defined $method and defined $count;

    return $self->mock_expect( $method => %params, count => $count );
};


=item B<mock_expect_maximum_call_count>( I<method> : Str, I<count> : Int, :I<args> : ArrayRef[Any] ) : Self

Sets the number of times a method may be called before a test failure is
triggered.

=cut

sub mock_expect_maximum_call_count {
    my ($self, $method, $count, %params) = @_;

    Exception::Argument->throw(
        message => 'Usage: $mock->mock_expect_maximum_call_count( METHOD, COUNT => PARAMS )'
    ) unless defined $method and defined $count;

    return $self->mock_expect( $method => %params, maximum => $count );
};


=item B<mock_expect_minimum_call_count>( I<method> : Str, I<count> : Int, :I<args> : ArrayRef[Any] ) : Self

Sets the number of times to call a method to prevent a failure on the tally.

=cut

sub mock_expect_minimum_call_count {
    my ($self, $method, $count, %params) = @_;

    Exception::Argument->throw(
        message => 'Usage: $mock->mock_expect_minimum_call_count( METHOD, COUNT => PARAMS )'
    ) unless defined $method and defined $count;

    return $self->mock_expect( $method => %params, minimum => $count );
};


=item B<mock_expect_never>( I<method> : Str, :I<args> : ArrayRef[Any] ) : Self

Convenience method for barring a method call.

=cut

sub mock_expect_never {
    my ($self, $method, %params) = @_;

    Exception::Argument->throw(
        message => 'Usage: $mock->mock_expect_never( METHOD => PARAMS )'
    ) unless defined $method;

    return $self->mock_expect( $method => %params, maximum => 0 );
};


=item B<mock_expect_once>( I<method> : Str, :I<args> : ArrayRef[Any] ) : Self

Convenience method for a single method call.

=cut

sub mock_expect_once {
    my ($self, $method, %params) = @_;

    Exception::Argument->throw(
        message => 'Usage: $mock->mock_expect_once( METHOD => PARAMS )'
    ) unless defined $method;

    return $self->mock_expect( $method => %params, count => 1 );
};


=item B<mock_expect_at_least_once>( I<method> : Str, :I<args> : ArrayRef[Any] ) : Self

Convenience method for requiring a method call.

=cut

sub mock_expect_at_least_once {
    my ($self, $method, %params) = @_;

    Exception::Argument->throw(
        message => 'Usage: $mock->mock_expect_at_least_once( METHOD => PARAMS )'
    ) unless defined $method;

    return $self->mock_expect( $method => %params, minimum => 1 );
};


=item B<_mock_emulate_call>( I<method> : Str, I<timing> : Int, I<args> : Array ) : Any

Finds the return value matching the incoming arguments.  If there is no
matching value found then an error is triggered.

=cut

sub _mock_emulate_call {
    my ($self, $method, $timing, @args) = @_;

    assert_not_null($method) if ASSERT;
    assert_not_null($timing) if ASSERT;

    my $rules_for_method = $self->_mock_action->{$method};

    return if not defined $rules_for_method
              or (ref $rules_for_method || '') ne 'ARRAY';

    RULE:
    foreach my $rule (@$rules_for_method) {
        if (defined $rule->{at}) {
            next unless $timing == $rule->{at};
        };

        if (exists $rule->{args}) {
            my @rule_args = (ref $rule->{args} || '') eq 'ARRAY'
                            ? @{ $rule->{args} }
                            : ( $rule->{args} );

            # number of args matches?
            next unless @args == @rule_args;

            # iterate args
            foreach my $i (0 .. @rule_args - 1) {
                my $rule_arg = $rule_args[$i];
                if ((ref $rule_arg || '') eq 'Regexp') {
                    next RULE unless $args[$i] =~ $rule_arg;
                }
                elsif (ref $rule_arg) {
                    # TODO: use Test::Deep::NoTest
                    eval {
                        assert_deep_equals($rule_arg, $args[$i]);
                    };
                    next RULE if $EVAL_ERROR;
                }
                else {
                    # TODO: do not use eval
                    eval {
                        assert_equals($rule_arg, $args[$i]);
                    };
                    next RULE if $EVAL_ERROR;
                };
            };
        };

        if (ref $rule->{value} eq 'CODE') {
            return $rule->{value}->(
                $method, $timing, @args
            );
        }
        elsif (defined $rule->{value}) {
            return $rule->{value};
        };
    };

    return;
};


=item B<_mock_add_call>( I<method> : Str, I<args> : Array ) : Int

Adds one to the call count of a method and returns previous value.

=cut

sub _mock_add_call {
    my ($self, $method, @args) = @_;

    assert_not_null($method) if ASSERT;

    assert_equals('HASH', ref $self->_mock_call) if ASSERT;
    return $self->_mock_call->{$method}++;
};

=item B<_mock_check_expectations>( I<method> : Str, I<timing> : Num, I<args> : Array ) : Self

Tests the arguments against expectations.

=cut

sub _mock_check_expectations {
    my ($self, $method, $timing, @args) = @_;

    assert_not_null($method) if ASSERT;
    assert_not_null($timing) if ASSERT;

    my $rules_for_method = $self->_mock_expectation->{$method};

    return if not defined $rules_for_method
              or (ref $rules_for_method || '') ne 'ARRAY';

    my $e;

    RULE:
    foreach my $rule (@$rules_for_method) {
        if (defined $rule->{at}) {
            next RULE unless $timing == $rule->{at};
        };

        eval {
            TRY: {
                if (exists $rule->{args}) {
                    my @rule_args = (ref $rule->{args} || '') eq 'ARRAY'
                                    ? @{ $rule->{args} }
                                    : ( $rule->{args} );

                    # number of args matches?
                    next TRY unless @args == @rule_args;

                    # iterate args
                    foreach my $i (0 .. @rule_args - 1) {
                        my $rule_arg = $rule_args[$i];
                        if ((ref $rule_arg || '') eq 'Regexp') {
                            assert_matches($rule_arg, $args[$i]);
                        }
                        elsif (ref $rule_arg) {
                            assert_deep_equals($rule_arg, $args[$i]);
                        }
                        else {
                            assert_equals($rule_arg, $args[$i]);
                        };
                    };
                };

                $rule->{call} ++;

                fail( [
                    'Maximum call count (%d) for method (%s) at call (%d)',
                    $rule->{maximum}, $method, $timing
                ] ) if (defined $rule->{maximum} and $rule->{call} > $rule->{maximum});

                fail( [
                    'Expected call count (%d) for method (%s) at call (%d)',
                    $rule->{count}, $method, $timing
                ] ) if (defined $rule->{count} and $rule->{call} > $rule->{count});

                if (defined $rule->{assertion}) {
                    if (ref $rule->{assertion} eq 'CODE') {
                        fail( $rule->{assertion}->($method, $timing, @args) );
                    }
                    else {
                        fail( $rule->{assertion} );
                    };
                };
            };
        };
        $e ||= Exception::Fatal->catch if $EVAL_ERROR;
    };

    $e->throw if $e;

    return;
};


1;


=back

=begin umlwiki

= Class Diagram =

[                                   <<role>>
                         Test::Mock::Class::Role::Object
 -----------------------------------------------------------------------------
 #_mock_call : HashRef
 #_mock_expectation : HashRef
 #_mock_action : HashRef
 -----------------------------------------------------------------------------
 +mock_return( method : Str, :value : Any, :at : Int, :args : ArrayRef[Any] ) : Self
 +mock_return_at( at : Int, method : Str, :args : ArrayRef[Any] ) : Self
 +mock_throw( method : Str, :at : Int, :exception : Str, :args : ArrayRef[Any] ) : Self
 +mock_throw_at( at : Int, method : Str, :args : ArrayRef[Any] ) : Self
 +mock_expect( method : Str, :at : Int, :minimum : Int, :maximum : Int, :count : Int, :args : ArrayRef[Any] ) : Self
 +mock_expect_at( at : Int, method : Str, :args : ArrayRef[Any] ) : Self
 +mock_expect_call_count( method : Str, count : Int, :args : ArrayRef[Any] ) : Self
 +mock_expect_maximum_call_count( method : Str, count : Int, :args : ArrayRef[Any] ) : Self
 +mock_expect_minimum_call_count( method : Str, count : Int, :args : ArrayRef[Any] ) : Self
 +mock_expect_never( method : Str, :args : ArrayRef[Any] ) : Self
 +mock_expect_once( method : Str, :args : ArrayRef[Any] ) : Self
 +mock_expect_at_least_once( method : Str, :args : ArrayRef[Any] ) : Self
 +mock_invoke( method : Str, args : Array ) : Any
 +mock_tally() : Self
                                                                              ]

=end umlwiki

=head1 SEE ALSO

L<Test::Mock::Class>.

=head1 BUGS

The expectations and return values should be refactored as objects rather than
complex structure.

The API is not stable yet and can be changed in future.

=head1 AUTHOR

Piotr Roszatycki <dexter@cpan.org>

=head1 LICENSE

Based on SimpleTest, an open source unit test framework for the PHP
programming language, created by Marcus Baker, Jason Sweat, Travis Swicegood,
Perrick Penet and Edward Z. Yang.

Copyright (c) 2009, 2010 Piotr Roszatycki <dexter@cpan.org>.

This program is free software; you can redistribute it and/or modify it
under GNU Lesser General Public License.
