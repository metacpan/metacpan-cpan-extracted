package Venus::Role::Comparable;

use 5.018;

use strict;
use warnings;

use Venus::Role 'with';

require Scalar::Util;
require Venus::Type;

# METHODS

sub eq {
  my ($self, $data) = @_;

  $data = Venus::Type->new(value => $data)->deduce;

  if (Scalar::Util::refaddr($self) eq Scalar::Util::refaddr($data)) {
    return true;
  }
  if (Scalar::Util::blessed($data) && !$data->isa('Venus::Kind')) {
    return false;
  }
  if ($self->comparer('eq') eq 'numified') {
    return $self->numified == $data->numified ? true : false;
  }
  elsif ($self->comparer('eq') eq 'stringified') {
    return $self->stringified eq $data->stringified ? true : false;
  }
  elsif (my $method = $self->comparer('eq')) {
    return $self->$method eq $data->$method ? true : false;
  }
  else {
    return false;
  }
}

sub ge {
  my ($self, $data) = @_;

  if ($self->gt($data) || $self->eq($data)) {
    return true;
  }
  else {
    return false;
  }
}

sub gele {
  my ($self, $ge, $le) = @_;

  if ($self->ge($ge) && $self->le($le)) {
    return true;
  }
  else {
    return false;
  }
}

sub gt {
  my ($self, $data) = @_;

  $data = Venus::Type->new(value => $data)->deduce;

  if (Scalar::Util::refaddr($self) eq Scalar::Util::refaddr($data)) {
    return false;
  }
  if (Scalar::Util::blessed($data) && !$data->isa('Venus::Kind')) {
    return false;
  }
  if ($self->comparer('gt') eq 'numified') {
    return $self->numified > $data->numified ? true : false;
  }
  elsif ($self->comparer('gt') eq 'stringified') {
    return $self->stringified gt $data->stringified ? true : false;
  }
  elsif (my $method = $self->comparer('gt')) {
    return $self->$method gt $data->$method ? true : false;
  }
  else {
    return false;
  }
}

sub gtlt {
  my ($self, $gt, $lt) = @_;

  if ($self->gt($gt) && $self->lt($lt)) {
    return true;
  }
  else {
    return false;
  }
}

sub is {
  my ($self, $data) = @_;

  if (!ref $data) {
    return false;
  }
  if (Scalar::Util::refaddr($self) eq Scalar::Util::refaddr($data)) {
    return true;
  }
  else {
    return false;
  }
}

sub lt {
  my ($self, $data) = @_;

  $data = Venus::Type->new(value => $data)->deduce;

  if (Scalar::Util::refaddr($self) eq Scalar::Util::refaddr($data)) {
    return false;
  }
  if (Scalar::Util::blessed($data) && !$data->isa('Venus::Kind')) {
    return false;
  }
  if ($self->comparer('lt') eq 'numified') {
    return $self->numified < $data->numified ? true : false;
  }
  elsif ($self->comparer('lt') eq 'stringified') {
    return $self->stringified lt $data->stringified ? true : false;
  }
  elsif (my $method = $self->comparer('lt')) {
    return $self->$method lt $data->$method ? true : false;
  }
  else {
    return false;
  }
}

sub le {
  my ($self, $data) = @_;

  if ($self->lt($data) || $self->eq($data)) {
    return true;
  }
  else {
    return false;
  }
}

sub ne {
  my ($self, $data) = @_;

  return $self->eq($data) ? false : true;
}

sub st {
  my ($self, $data) = @_;

  if (!Scalar::Util::blessed($data)) {
    return false;
  }
  if (Scalar::Util::refaddr($self) eq Scalar::Util::refaddr($data)) {
    return true;
  }
  if ($data->isa($self->class)) {
    return true;
  }
  else {
    return false;
  }
}

sub tv {
  my ($self, $data) = @_;

  if (!Scalar::Util::blessed($data)) {
    return false;
  }
  if (Scalar::Util::refaddr($self) eq Scalar::Util::refaddr($data)) {
    return true;
  }
  if ($data->isa($self->class)) {
    return $self->eq($data);
  }
  else {
    return false;
  }
}

# EXPORTS

sub EXPORT {
  ['eq', 'ge', 'gele', 'gt', 'gtlt', 'is', 'lt', 'le', 'ne', 'st', 'tv']
}

1;



=head1 NAME

Venus::Role::Comparable - Comparable Role

=cut

=head1 ABSTRACT

Comparable Role for Perl 5

=cut

=head1 SYNOPSIS

  package Example;

  use Venus::Class;

  base 'Venus::Kind';

  with 'Venus::Role::Comparable';

  sub numified {
    return 2;
  }

  package main;

  my $example = Example->new;

  # my $result = $example->eq(2);

=cut

=head1 DESCRIPTION

This package modifies the consuming package and provides methods for performing
numerical and stringwise comparision operations or any object or raw data type.

=cut

=head1 METHODS

This package provides the following methods:

=cut

=head2 eq

  eq(any $arg) (boolean)

The eq method performs an I<"equals"> operation using the invocant and the
argument provided. The operation will be performed as either a numerical or
stringwise operation based upon the preference (i.e. the return value of the
L</comparer> method) of the invocant.

I<Since C<0.08>>

=over 4

=item eq example 1

  package main;

  my $example = Example->new;

  my $result = $example->eq($example);

  # 1

=back

=over 4

=item eq example 2

  package main;

  my $example = Example->new;

  my $result = $example->eq([1,2]);

  # 0

=back

=over 4

=item eq example 3

  package main;

  my $example = Example->new;

  my $result = $example->eq({1..4});

  # 0

=back

=cut

=head2 ge

  ge(any $arg) (boolean)

The ge method performs a I<"greater-than-or-equal-to"> operation using the
invocant and argument provided. The operation will be performed as either a
numerical or stringwise operation based upon the preference (i.e. the return
value of the L</comparer> method) of the invocant.

I<Since C<0.08>>

=over 4

=item ge example 1

  package main;

  my $example = Example->new;

  my $result = $example->ge(3);

  # 0

=back

=over 4

=item ge example 2

  package main;

  my $example = Example->new;

  my $result = $example->ge($example);

  # 1

=back

=over 4

=item ge example 3

  package main;

  my $example = Example->new;

  my $result = $example->ge([1,2,3]);

  # 0

=back

=cut

=head2 gele

  gele(any $arg1, any $arg2) (boolean)

The gele method performs a I<"greater-than-or-equal-to"> operation on the 1st
argument, and I<"lesser-than-or-equal-to"> operation on the 2nd argument. The
operation will be performed as either a numerical or stringwise operation based
upon the preference (i.e. the return value of the L</comparer> method) of the
invocant.

I<Since C<0.08>>

=over 4

=item gele example 1

  package main;

  my $example = Example->new;

  my $result = $example->gele(1, 3);

  # 1

=back

=over 4

=item gele example 2

  package main;

  my $example = Example->new;

  my $result = $example->gele(2, []);

  # 0

=back

=over 4

=item gele example 3

  package main;

  my $example = Example->new;

  my $result = $example->gele(0, '3');

  # 1

=back

=cut

=head2 gt

  gt(any $arg) (boolean)

The gt method performs a I<"greater-than"> operation using the invocant and
argument provided. The operation will be performed as either a numerical or
stringwise operation based upon the preference (i.e. the return value of the
L</comparer> method) of the invocant.

I<Since C<0.08>>

=over 4

=item gt example 1

  package main;

  my $example = Example->new;

  my $result = $example->gt({1..2});

  # 0

=back

=over 4

=item gt example 2

  package main;

  my $example = Example->new;

  my $result = $example->gt(1.9998);

  # 1

=back

=over 4

=item gt example 3

  package main;

  my $example = Example->new;

  my $result = $example->gt(\1_000_000);

  # 0

=back

=cut

=head2 gtlt

  gtlt(any $arg1, any $arg2) (boolean)

The gtlt method performs a I<"greater-than"> operation on the 1st argument, and
I<"lesser-than"> operation on the 2nd argument. The operation will be performed
as either a numerical or stringwise operation based upon the preference (i.e.
the return value of the L</comparer> method) of the invocant.

I<Since C<0.08>>

=over 4

=item gtlt example 1

  package main;

  my $example = Example->new;

  my $result = $example->gtlt('1', 3);

  # 1

=back

=over 4

=item gtlt example 2

  package main;

  my $example = Example->new;

  my $result = $example->gtlt({1..2}, {1..4});

  # 0

=back

=over 4

=item gtlt example 3

  package main;

  my $example = Example->new;

  my $result = $example->gtlt('.', ['.']);

  # 1

=back

=cut

=head2 is

  is(any $arg) (boolean)

The is method performs an I<"is-exactly"> operation using the invocant and the
argument provided. If the argument provided is blessed and exactly the same as
the invocant (i.e. shares the same address space) the operation will return
truthy.

I<Since C<1.80>>

=over 4

=item is example 1

  package main;

  my $example = Example->new;

  my $result = $example->is($example);

  # 1

=back

=over 4

=item is example 2

  package main;

  my $example = Example->new;

  my $result = $example->is([1,2]);

  # 0

=back

=over 4

=item is example 3

  package main;

  my $example = Example->new;

  my $result = $example->is(Example->new);

  # 0

=back

=cut

=head2 le

  le(any $arg) (boolean)

The le method performs a I<"lesser-than-or-equal-to"> operation using the
invocant and argument provided. The operation will be performed as either a
numerical or stringwise operation based upon the preference (i.e. the return
value of the L</comparer> method) of the invocant.

I<Since C<0.08>>

=over 4

=item le example 1

  package main;

  my $example = Example->new;

  my $result = $example->le('9');

  # 1

=back

=over 4

=item le example 2

  package main;

  my $example = Example->new;

  my $result = $example->le([1..2]);

  # 1

=back

=over 4

=item le example 3

  package main;

  my $example = Example->new;

  my $result = $example->le(\1);

  # 0

=back

=cut

=head2 lt

  lt(any $arg) (boolean)

The lt method performs a I<"lesser-than"> operation using the invocant and
argument provided. The operation will be performed as either a numerical or
stringwise operation based upon the preference (i.e. the return value of the
L</comparer> method) of the invocant.

I<Since C<0.08>>

=over 4

=item lt example 1

  package main;

  my $example = Example->new;

  my $result = $example->lt(qr/.*/);

  # 1

=back

=over 4

=item lt example 2

  package main;

  my $example = Example->new;

  my $result = $example->lt('.*');

  # 0

=back

=over 4

=item lt example 3

  package main;

  my $example = Example->new;

  my $result = $example->lt('5');

  # 1

=back

=cut

=head2 ne

  ne(any $arg) (boolean)

The ne method performs a I<"not-equal-to"> operation using the invocant and
argument provided. The operation will be performed as either a numerical or
stringwise operation based upon the preference (i.e. the return value of the
L</comparer> method) of the invocant.

I<Since C<0.08>>

=over 4

=item ne example 1

  package main;

  my $example = Example->new;

  my $result = $example->ne([1,2]);

  # 1

=back

=over 4

=item ne example 2

  package main;

  my $example = Example->new;

  my $result = $example->ne([2]);

  # 1

=back

=over 4

=item ne example 3

  package main;

  my $example = Example->new;

  my $result = $example->ne(qr/2/);

  # 1

=back

=cut

=head2 st

  st(object $arg) (boolean)

The st method performs a I<"same-type"> operation using the invocant and
argument provided. If the argument provided is an instance of the invocant, or
a subclass, the operation will return truthy.

I<Since C<1.80>>

=over 4

=item st example 1

  package main;

  my $example = Example->new;

  my $result = $example->st($example);

  # 1

=back

=over 4

=item st example 2

  package main;

  use Venus::Number;

  my $example = Example->new;

  my $result = $example->st(Venus::Number->new(2));

  # 0

=back

=over 4

=item st example 3

  package main;

  use Venus::String;

  my $example = Example->new;

  my $result = $example->st(Venus::String->new('2'));

  # 0

=back

=over 4

=item st example 4

  package Example2;

  use base 'Example';

  package main;

  use Venus::String;

  my $example = Example2->new;

  my $result = $example->st(Example2->new);

  # 1

=back

=cut

=head2 tv

  tv(any $arg) (boolean)

The tv method performs a I<"type-and-value-equal-to"> operation using the
invocant and argument provided. The operation will be performed as either a
numerical or stringwise operation based upon the preference (i.e. the return
value of the L</comparer> method) of the invocant.

I<Since C<0.08>>

=over 4

=item tv example 1

  package main;

  my $example = Example->new;

  my $result = $example->tv($example);

  # 1

=back

=over 4

=item tv example 2

  package main;

  use Venus::Number;

  my $example = Example->new;

  my $result = $example->tv(Venus::Number->new(2));

  # 0

=back

=over 4

=item tv example 3

  package main;

  use Venus::String;

  my $example = Example->new;

  my $result = $example->tv(Venus::String->new('2'));

  # 0

=back

=over 4

=item tv example 4

  package main;

  use Venus::String;

  my $example = Example->new;

  my $result = $example->tv(Example->new);

  # 1

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