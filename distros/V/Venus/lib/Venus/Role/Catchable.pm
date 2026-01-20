package Venus::Role::Catchable;

use 5.018;

use strict;
use warnings;

# IMPORTS

use Venus::Role 'fault';

# AUDITS

sub AUDIT {
  my ($self, $from) = @_;

  if (!$from->does('Venus::Role::Tryable')) {
    fault "${self} requires ${from} to consume Venus::Role::Tryable";
  }

  return $self;
}

# METHODS

sub catch {
  my ($self, $method, @args) = @_;

  my @result = $self->try($method, @args)->error(\my $error)->result;

  return wantarray ? ($error ? ($error, undef) : ($error, @result)) : $error;
}

sub caught {
  my ($self, $data, $type, $code) = @_;

  require Scalar::Util;

  ($type, my($name)) = @$type if ref $type eq 'ARRAY';

  my $is_true = $data
    && Scalar::Util::blessed($data)
    && $data->isa('Venus::Error')
    && $data->isa($type || 'Venus::Error')
    && ($data->name ? $data->of($name || '') : !$name);

  return undef unless $is_true;

  local $_ = $data;
  return $code ? $code->($data) : $data;
}

sub maybe {
  my ($self, $method, @args) = @_;

  my @result = $self->try($method, @args)->error(\my $error)->result;

  return wantarray ? ($error ? (undef) : (@result)) : ($error ? undef : $result[0]);
}

# EXPORTS

sub EXPORT {
  ['catch', 'caught', 'maybe']
}

1;



=head1 NAME

Venus::Role::Catchable - Catchable Role

=cut

=head1 ABSTRACT

Catchable Role for Perl 5

=cut

=head1 SYNOPSIS

  package Example;

  use Venus::Class;

  use Venus 'error';

  with 'Venus::Role::Tryable';
  with 'Venus::Role::Catchable';

  sub pass {
    true;
  }

  sub fail {
    error;
  }

  package main;

  my $example = Example->new;

  # my $error = $example->catch('fail');

=cut

=head1 DESCRIPTION

This package modifies the consuming package and provides methods for trapping
errors thrown from dispatched method calls.

=cut

=head1 METHODS

This package provides the following methods:

=cut

=head2 catch

  catch(string $method, any @args) (any)

The catch method traps any errors raised by executing the dispatched method
call and returns the error string or error object. This method can return a
list of values in list-context. This method supports dispatching, i.e.
providing a method name and arguments whose return value will be acted on by
this method.

I<Since C<0.01>>

=over 4

=item catch example 1

  package main;

  my $example = Example->new;

  my $catch = $example->catch('fail');

  # bless({...}, "Venus::Error")

=back

=over 4

=item catch example 2

  package main;

  my $example = Example->new;

  my $catch = $example->catch('pass');

  # undef

=back

=over 4

=item catch example 3

  package main;

  my $example = Example->new;

  my ($catch, $result) = $example->catch('pass');

  # (undef, 1)

=back

=over 4

=item catch example 4

  package main;

  my $example = Example->new;

  my ($catch, $result) = $example->catch('fail');

  # (bless({...}, "Venus::Error"), undef)

=back

=cut

=head2 caught

  caught(object $error, string | tuple[string, string] $identity, coderef $block) (any)

The caught method evaluates the value provided and validates its identity and
name (if provided) then executes the code block (if provided) returning the
result of the callback. If no callback is provided this function returns the
exception object on success and C<undef> on failure.

I<Since C<4.15>>

=over 4

=item caught example 1

  package main;

  my $example = Example->new;

  my $catch = $example->catch('fail');

  my $result = $example->caught($catch);

  # bless(..., 'Venus::Error')

=back

=over 4

=item caught example 2

  package main;

  my $example = Example->new;

  my $catch = $example->catch('fail');

  my $result = $example->caught($catch, 'Venus::Error');

  # bless(..., 'Venus::Error')

=back

=over 4

=item caught example 3

  package main;

  my $example = Example->new;

  my $catch = $example->catch('fail');

  my $result = $example->caught($catch, 'Venus::Error', sub{
    $example->{caught} = $_;
  });

  ($example, $result)

  # (bless(..., 'Example'), bless(..., 'Venus::Error'))

=back

=over 4

=item caught example 4

  package main;

  my $example = Example->new;

  my $catch = $example->catch('fail');

  $catch->name('on.issue');

  my $result = $example->caught($catch, ['Venus::Error', 'on.issue']);

  # bless(..., 'Venus::Error')

=back

=over 4

=item caught example 5

  package main;

  my $example = Example->new;

  my $catch = $example->catch('fail');

  $catch->name('on.issue');

  my $result = $example->caught($catch, ['Venus::Error', 'on.issue'], sub{
    $example->{caught} = $_;
  });

  ($example, $result)

  # (bless(..., 'Example'), bless(..., 'Venus::Error'))

=back

=over 4

=item caught example 6

  package main;

  my $example = Example->new;

  my $catch = $example->catch('fail');

  my $result = $example->caught($catch, ['Venus::Error', 'on.issue']);

  # undef

=back

=over 4

=item caught example 7

  package main;

  my $example = Example->new;

  my $catch;

  my $result = $example->caught($catch);

  # undef

=back

=cut

=head2 maybe

  maybe(string $method, any @args) (any)

The maybe method traps any errors raised by executing the dispatched method
call and returns undefined on error, effectively supressing the error. This
method can return a list of values in list-context. This method supports
dispatching, i.e.  providing a method name and arguments whose return value
will be acted on by this method.

I<Since C<2.91>>

=over 4

=item maybe example 1

  package main;

  my $example = Example->new;

  my $maybe = $example->maybe('fail');

  # undef

=back

=over 4

=item maybe example 2

  package main;

  my $example = Example->new;

  my $maybe = $example->maybe('pass');

  # true

=back

=over 4

=item maybe example 3

  package main;

  my $example = Example->new;

  my (@maybe) = $example->maybe(sub {1..4});

  # (1..4)

=back

=cut

=head1 AUTHORS

Awncorp, C<awncorp@cpan.org>

=cut

=head1 LICENSE

Copyright (C) 2022, Awncorp, C<awncorp@cpan.org>.

This program is free software, you can redistribute it and/or modify it under
the terms of the Apache license version 2.0.

=cut