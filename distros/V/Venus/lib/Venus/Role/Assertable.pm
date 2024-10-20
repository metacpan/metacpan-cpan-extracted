package Venus::Role::Assertable;

use 5.018;

use strict;
use warnings;

use Venus::Role 'fault';

# METHODS

sub assert {
  my ($self, $data) = @_;

  return $self->assertion->result($data);
}

sub assertion {
  my ($self) = @_;

  require Venus::Assert;

  my $class = ref $self || $self;

  my $assert = Venus::Assert->new($class);

  $assert->match('hashref')->format(sub{
    $class->new($_)
  });

  $assert->accept($class);

  return $assert;
}

sub check {
  my ($self, $data) = @_;

  return $self->assertion->valid($data);
}

sub coerce {
  my ($self, $data) = @_;

  return $self->assertion->coerce($data);
}

sub make {
  my ($self, $data) = @_;

  return UNIVERSAL::isa($data, ref $self || $self)
    ? $data
    : $self->assert($data);
}

# EXPORTS

sub EXPORT {
  ['assert', 'assertion', 'check', 'coerce', 'make']
}

1;



=head1 NAME

Venus::Role::Assertable - Assertable Role

=cut

=head1 ABSTRACT

Assertable Role for Perl 5

=cut

=head1 SYNOPSIS

  package Example;

  use Venus::Class;
  use Venus::Assert;

  with 'Venus::Role::Assertable';

  sub assertion {
    Venus::Assert->new('Example')->accept('Example')
  }

  package main;

  my $example = Example->new;

  # $example->check;

=cut

=head1 DESCRIPTION

This package modifies the consuming package and requires methods for making the
object assertable.

=cut

=head1 METHODS

This package provides the following methods:

=cut

=head2 assert

  assert(any $data) (any)

The assert method returns the data provided if it passes the registered type
constraints, or throws an exception.

I<Since C<1.23>>

=over 4

=item assert example 1

  # given: synopsis

  package main;

  my $assert = $example->assert;

  # Exception! (isa Venus::Check::Error)

=back

=over 4

=item assert example 2

  # given: synopsis

  package main;

  my $assert = $example->assert({});

  # Exception! (isa Venus::Check::Error)

=back

=over 4

=item assert example 3

  # given: synopsis

  package main;

  my $assert = $example->assert($example);

  # bless({}, "Example")

=back

=cut

=head2 assertion

  assertion() (Venus::Assert)

The assertion method receives no arguments and should returns a
L<Venus::Assert> object.

I<Since C<1.23>>

=over 4

=item assertion example 1

  package main;

  my $example = Example->new;

  my $assertion = $example->assertion;

  # bless({name => "Example"}, "Venus::Assert")

=back

=cut

=head2 check

  check(any $data) (boolean)

The check method returns true if the data provided passes the registered type
constraints, or returns false.

I<Since C<1.23>>

=over 4

=item check example 1

  # given: synopsis

  package main;

  my $check = $example->check;

  # 0

=back

=over 4

=item check example 2

  # given: synopsis

  package main;

  my $check = $example->check({});

  # 0

=back

=over 4

=item check example 3

  # given: synopsis

  package main;

  my $check = $example->check($example);

  # 1

=back

=cut

=head2 coerce

  coerce(any $data) (any)

The coerce method returns a coerced value if the data provided matches any of
the registered type coercions, or returns the data provided.

I<Since C<1.23>>

=over 4

=item coerce example 1

  # given: synopsis

  package main;

  my $assertion = $example->assertion;

  $assertion->match('string')->format(sub{ucfirst(lc($_))});

  my $coerce = $assertion->coerce;

  # undef

=back

=over 4

=item coerce example 2

  # given: synopsis

  package main;

  my $assertion = $example->assertion;

  $assertion->match('string')->format(sub{ucfirst(lc($_))});

  my $coerce = $assertion->coerce({});

  # {}

=back

=over 4

=item coerce example 3

  # given: synopsis

  package main;

  my $assertion = $example->assertion;

  $assertion->match('string')->format(sub{ucfirst(lc($_))});

  my $coerce = $assertion->coerce('hello');

  # "Hello"

=back

=cut

=head2 make

  make(any $data) (object)

The make method returns an instance of the invocant, if the data provided
passes the registered type constraints, allowing for any coercion, or throws an
exception. If the data provided is itself an instance of the invocant it will
be returned unaltered.

I<Since C<1.23>>

=over 4

=item make example 1

  # given: synopsis

  package main;

  my $make = $example->make;

  # Exception! (isa Venus::Check::Error)

=back

=over 4

=item make example 2

  # given: synopsis

  package main;

  my $make = $example->make($example);

  # bless({}, "Example")

=back

=over 4

=item make example 3

  # given: synopsis

  package main;

  my $make = $example->make({});

  # Exception! (isa Venus::Check::Error)

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