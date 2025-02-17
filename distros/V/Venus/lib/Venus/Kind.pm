package Venus::Kind;

use 5.018;

use strict;
use warnings;

use Venus::Class 'with';

with 'Venus::Role::Boxable';
with 'Venus::Role::Tryable';
with 'Venus::Role::Catchable';
with 'Venus::Role::Comparable';
with 'Venus::Role::Deferrable';
with 'Venus::Role::Dumpable';
with 'Venus::Role::Digestable';
with 'Venus::Role::Doable';
with 'Venus::Role::Matchable';
with 'Venus::Role::Printable';
with 'Venus::Role::Reflectable';
with 'Venus::Role::Testable';
with 'Venus::Role::Throwable';
with 'Venus::Role::Assertable';
with 'Venus::Role::Serializable';
with 'Venus::Role::Mockable';
with 'Venus::Role::Patchable';

# METHODS

sub checksum {
  my ($self) = @_;

  return $self->digest('md5', 'stringified');
}

sub comparer {
  my ($self, $operation) = @_;

  if (lc($operation) eq 'eq') {
    return 'checksum';
  }
  if (lc($operation) eq 'gt') {
    return 'numified';
  }
  if (lc($operation) eq 'lt') {
    return 'numified';
  }
  else {
    return 'stringified';
  }
}

sub numified {
  my ($self) = @_;

  return CORE::length($self->stringified);
}

sub renew {
  my ($self, @args) = @_;

  my $data = $self->ARGS(@args);

  for my $attr (@{$self->meta->attrs}) {
    $data->{$attr} = $self->$attr if exists $self->{$attr} && !exists $data->{$attr};
  }

  return $self->class->new($data);
}

sub safe {
  my ($self, $method, @args) = @_;

  my $result = $self->trap($method, @args);

  return(wantarray ? (@$result) : $result->[0]);
}

sub self {
  my ($self) = @_;

  return $self;
}

sub stringified {
  my ($self) = @_;

  return $self->dump($self->can('value') ? 'value' : ());
}

sub trap {
  my ($self, $method, @args) = @_;

  no strict;
  no warnings;

  my $result = [[],[],[]];

  return(wantarray ? (@$result) : $result->[0]) if !$method;

  local ($!, $?, $@, $^E);

  local $SIG{__DIE__} = sub{
    push @{$result->[2]}, @_;
  };

  local $SIG{__WARN__} = sub{
    push @{$result->[1]}, @_;
  };

  push @{$result->[0]}, eval {
    local $_ = $self;
    $self->$method(@args);
  };

  return(wantarray ? (@$result) : $result->[0]);
}

1;



=head1 NAME

Venus::Kind - Kind Base Class

=cut

=head1 ABSTRACT

Kind Base Class for Perl 5

=cut

=head1 SYNOPSIS

  package Example;

  use Venus::Class;

  base 'Venus::Kind';

  package main;

  my $example = Example->new;

  # bless({}, "Example")

=cut

=head1 DESCRIPTION

This package provides identity and methods common across all L<Venus> classes.

=cut

=head1 INTEGRATES

This package integrates behaviors from:

L<Venus::Role::Assertable>

L<Venus::Role::Boxable>

L<Venus::Role::Catchable>

L<Venus::Role::Comparable>

L<Venus::Role::Deferrable>

L<Venus::Role::Digestable>

L<Venus::Role::Doable>

L<Venus::Role::Dumpable>

L<Venus::Role::Matchable>

L<Venus::Role::Mockable>

L<Venus::Role::Patchable>

L<Venus::Role::Printable>

L<Venus::Role::Reflectable>

L<Venus::Role::Serializable>

L<Venus::Role::Testable>

L<Venus::Role::Throwable>

L<Venus::Role::Tryable>

=cut

=head1 METHODS

This package provides the following methods:

=cut

=head2 assertion

  assertion() (Venus::Assert)

The assertion method returns a L<Venus::Assert> object based on the invocant.

I<Since C<1.23>>

=over 4

=item assertion example 1

  # given: synopsis

  package main;

  my $assertion = $example->assertion;

  # bless({name => "Example"}, "Venus::Assert")

=back

=cut

=head2 checksum

  checksum() (string)

The checksum method returns an md5 hash string representing the stringified
object value (or the object itself).

I<Since C<0.08>>

=over 4

=item checksum example 1

  # given: synopsis;

  my $checksum = $example->checksum;

  # "859a86eed4b2d97eb7b830b02f06de32"

=back

=over 4

=item checksum example 2

  package Checksum::Example;

  use Venus::Class;

  base 'Venus::Kind';

  attr 'value';

  package main;

  my $example = Checksum::Example->new(value => 'example');

  my $checksum = $example->checksum;

  # "1a79a4d60de6718e8e5b326e338ae533"

=back

=cut

=head2 numified

  numified() (number)

The numified method returns the numerical representation of the object which is
typically the length (or character count) of the stringified object.

I<Since C<0.08>>

=over 4

=item numified example 1

  # given: synopsis;

  my $numified = $example->numified;

  # 22

=back

=over 4

=item numified example 2

  package Numified::Example;

  use Venus::Class;

  base 'Venus::Kind';

  attr 'value';

  package main;

  my $example = Numified::Example->new(value => 'example');

  my $numified = $example->numified;

  # 7

=back

=cut

=head2 renew

  renew(any @args) (object)

The renew method returns a new instance of the invocant by instantiating the
underlying class passing all recognized class attributes to the constructor.
B<Note:> This method is not analogous to C<clone>, i.e. attributes which are
references will be passed to the new object as references.

I<Since C<1.23>>

=over 4

=item renew example 1

  # given: synopsis

  package main;

  my $renew = $example->renew;

  # bless({}, "Example")

=back

=over 4

=item renew example 2

  package Example;

  use Venus::Class;

  base 'Venus::Kind';

  attr 'values';

  package main;

  my $example = Example->new(values => [1,2]);

  my $renew = $example->renew;

  # bless({values => [1,2]}, "Example")

=back

=over 4

=item renew example 3

  package Example;

  use Venus::Class;

  base 'Venus::Kind';

  attr 'keys';
  attr 'values';

  package main;

  my $example = Example->new(values => [1,2]);

  my $renew = $example->renew(keys => ['a','b']);

  # bless({keys => ["a","b"], values => [1,2]}, "Example")

=back

=cut

=head2 safe

  safe(string | coderef $code, any @args) (any)

The safe method dispatches the method call or executes the callback and returns
the result, supressing warnings and exceptions. If an exception is thrown this
method will return C<undef>. This method supports dispatching, i.e. providing a
method name and arguments whose return value will be acted on by this method.

I<Since C<0.08>>

=over 4

=item safe example 1

  # given: synopsis;

  my $safe = $example->safe('class');

  # "Example"

=back

=over 4

=item safe example 2

  # given: synopsis;

  my $safe = $example->safe(sub {
    ${_}->class / 2
  });

  # '0'

=back

=over 4

=item safe example 3

  # given: synopsis;

  my $safe = $example->safe(sub {
    die;
  });

  # undef

=back

=cut

=head2 self

  self() (any)

The self method returns the invocant.

I<Since C<1.23>>

=over 4

=item self example 1

  # given: synopsis

  package main;

  my $self = $example->self;

  # bless({}, "Example")

=back

=cut

=head2 stringified

  stringified() (string)

The stringified method returns the object, stringified (i.e. a dump of the
object's value).

I<Since C<0.08>>

=over 4

=item stringified example 1

  # given: synopsis;

  my $stringified = $example->stringified;

  # bless({}, 'Example')




=back

=over 4

=item stringified example 2

  package Stringified::Example;

  use Venus::Class;

  base 'Venus::Kind';

  attr 'value';

  package main;

  my $example = Stringified::Example->new(value => 'example');

  my $stringified = $example->stringified;

  # "example"

=back

=cut

=head2 trap

  trap(string | coderef $code, any @args) (tuple[arrayref, arrayref, arrayref])

The trap method dispatches the method call or executes the callback and returns
a tuple (i.e. a 3-element arrayref) with the results, warnings, and exceptions
from the code execution. If an exception is thrown, the results (i.e. the
1st-element) will be an empty arrayref. This method supports dispatching, i.e.
providing a method name and arguments whose return value will be acted on by
this method.

I<Since C<0.08>>

=over 4

=item trap example 1

  # given: synopsis;

  my $result = $example->trap('class');

  # ["Example"]

=back

=over 4

=item trap example 2

  # given: synopsis;

  my ($results, $warnings, $errors) = $example->trap('class');

  # (["Example"], [], [])

=back

=over 4

=item trap example 3

  # given: synopsis;

  my $trap = $example->trap(sub {
    ${_}->class / 2
  });

  # ["0"]

=back

=over 4

=item trap example 4

  # given: synopsis;

  my ($results, $warnings, $errors) = $example->trap(sub {
    ${_}->class / 2
  });

  # (["0"], ["Argument ... isn't numeric in division ..."], [])

=back

=over 4

=item trap example 5

  # given: synopsis;

  my $trap = $example->trap(sub {
    die;
  });

  # []

=back

=over 4

=item trap example 6

  # given: synopsis;

  my ($results, $warnings, $errors) = $example->trap(sub {
    die;
  });

  # ([], [], ["Died..."])

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