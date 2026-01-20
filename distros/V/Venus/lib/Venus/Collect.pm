package Venus::Collect;

use 5.018;

use strict;
use warnings;

# VENUS

use Venus::Class 'base', 'with';

# IMPORTS

use Venus 'list', 'pairs';

# INHERITS

base 'Venus::Kind::Utility';

# INTEGRATES

with 'Venus::Role::Valuable';

# METHODS

sub execute {
  my ($self, $code) = @_;

  require Scalar::Util;

  my $value = $self->value;

  return $value if !$code;

  my $blessed = !!Scalar::Util::blessed($value);

  if (!$blessed && ref $value eq 'ARRAY') {
    return $self->iterate_over_unblessed_arrayref($code, $value);
  }

  if (!$blessed && ref $value eq 'HASH') {
    return $self->iterate_over_unblessed_hashref($code, $value);
  }

  if ($blessed && $value->isa('Venus::Array')) {
    return $self->iterate_over_venus_array_object($code, $value);
  }

  if ($blessed && $value->isa('Venus::Set')) {
    return $self->iterate_over_venus_set_object($code, $value);
  }

  if ($blessed && $value->isa('Venus::Hash')) {
    return $self->iterate_over_venus_hash_object($code, $value);
  }

  if ($blessed && $value->isa('Venus::Map')) {
    return $self->iterate_over_venus_map_object($code, $value);
  }

  if ($blessed && UNIVERSAL::isa($value, 'ARRAY')) {
    return $self->iterate_over_blessed_arrayref($code, $value);
  }

  if ($blessed && UNIVERSAL::isa($value, 'HASH')) {
    return $self->iterate_over_blessed_hashref($code, $value);
  }

  return $value;
}

sub iterate {
  my ($self, $code, $pairs) = @_;

  my $result = [];

  for my $pair (list $pairs) {
    my ($key, $value) = (list $pair);

    local $_ = $value;

    my @returned = list $code->($key, $value);

    push @{$result}, [@returned] if @returned == 2;
  }

  return wantarray ? @{$result} : $result;
}

sub iterate_over_blessed_arrayref {
  my ($self, $code, $value) = @_;

  my @results = $self->iterate($code, scalar pairs [@{$value}]);

  @results = map {$$_[1]} sort {$$a[0] <=> $$b[0]} @results;

  return bless [@results], ref $value;
}

sub iterate_over_blessed_hashref {
  my ($self, $code, $value) = @_;

  my @results = $self->iterate($code, scalar pairs {%{$value}});

  @results = map +($$_[0], $$_[1]), @results;

  return bless {@results}, ref $value;
}

sub iterate_over_unblessed_arrayref {
  my ($self, $code, $value) = @_;

  my @results = $self->iterate($code, scalar pairs $value);

  @results = map {$$_[1]} sort {$$a[0] <=> $$b[0]} @results;

  return [@results];
}

sub iterate_over_unblessed_hashref {
  my ($self, $code, $value) = @_;

  my @results = $self->iterate($code, scalar pairs $value);

  @results = map +($$_[0], $$_[1]), @results;

  return {@results};
}

sub iterate_over_venus_array_object {
  my ($self, $code, $value) = @_;

  my @results = $self->iterate($code, scalar $value->pairs);

  @results = map {$$_[1]} sort {$$a[0] <=> $$b[0]} @results;

  return $value->new(value => [@results]);
}

sub iterate_over_venus_hash_object {
  my ($self, $code, $value) = @_;

  my @results = $self->iterate($code, scalar $value->pairs);

  @results = map +($$_[0], $$_[1]), @results;

  return $value->new(value => {@results});
}

sub iterate_over_venus_map_object {
  my ($self, $code, $value) = @_;

  my @results = $self->iterate($code, scalar $value->pairs);

  @results = map +($$_[0], $$_[1]), @results;

  return $value->renew(value => {@results});
}

sub iterate_over_venus_set_object {
  my ($self, $code, $value) = @_;

  my @results = $self->iterate($code, scalar $value->pairs);

  @results = map {$$_[1]} sort {$$a[0] <=> $$b[0]} @results;

  return $value->renew(value => [@results]);
}

1;



=head1 NAME

Venus::Collect - Collect Class

=cut

=head1 ABSTRACT

Collect Class for Perl 5

=cut

=head1 SYNOPSIS

  package main;

  use Venus::Collect;

  my $collect = Venus::Collect->new([1..4]);

  # bless({value => [1..4], 'Venus::Collect')

=cut

=head1 DESCRIPTION

This package provides a generic collection utility class designed to provide a
unified interface for working with data collections in Perl. It can wrap native
Perl arrayrefs and hashrefs, as well as compatible objects (e.g.,
L<Venus::Array>, L<Venus::Hash>, L<Venus::Set>, etc.), and apply functional
transformations through callbacks.

This class allows you to create a collection object, then use the C<execute>
method to iterate over the contents and selectively transform or filter the
data. The method supports both list-like and hash-like data structures,
handling key/value iteration when applicable.

It's especially useful in scenarios where you need to apply consistent
processing logic across various collection types without writing boilerplate
code for each type.

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Venus::Kind::Utility>

=cut

=head1 INTEGRATES

This package integrates behaviors from:

L<Venus::Role::Valuable>

=cut

=head1 METHODS

This package provides the following methods:

=cut

=head2 execute

  execute(coderef $code) (any)

The execute method accepts a callback (i.e. coderef) and executes the callback
for each key/value pair in the L</value>. For each iteration, the C<$_>
variable is set to the value (in the key/value pair). The callback will be
passed the key and values as arguments, made available via the C<@_> variable.
The callback must return a tuple, i.e. a list with the key and value, to be
returned as a result. This method returns a new instance of L</value> provided
consisting of only the key/value pairs returned from the callback.

I<Since C<4.15>>

=over 4

=item execute example 1

  # given: synopsis

  package main;

  my $execute = $collect->execute;

  # [1..4]

=back

=over 4

=item execute example 2

  # given: synopsis

  package main;

  my $execute = $collect->execute(sub{});

  # []

=back

=over 4

=item execute example 3

  # given: synopsis

  package main;

  my $execute = $collect->execute(sub{$_});

  # []

=back

=over 4

=item execute example 4

  # given: synopsis

  package main;

  my $execute = $collect->execute(sub{@_});

  # [1..4]

=back

=over 4

=item execute example 5

  # given: synopsis

  package main;

  my $execute = $collect->execute(sub{$_%2==0 ? (@_) : ()});

  # [2,4]

=back

=over 4

=item execute example 6

  package main;

  use Venus::Collect;

  my $collect = Venus::Collect->new(value => {1..8});

  my $execute = $collect->execute;

  # {1..8}

=back

=over 4

=item execute example 7

  package main;

  use Venus::Collect;

  my $collect = Venus::Collect->new(value => {1..8});

  my $execute = $collect->execute(sub{});

  # {}

=back

=over 4

=item execute example 8

  package main;

  use Venus::Collect;

  my $collect = Venus::Collect->new(value => {1..8});

  my $execute = $collect->execute(sub{$_});

  # {}

=back

=over 4

=item execute example 9

  package main;

  use Venus::Collect;

  my $collect = Venus::Collect->new(value => {1..8});

  my $execute = $collect->execute(sub{@_});

  # {1..8}

=back

=over 4

=item execute example 10

  package main;

  use Venus::Collect;

  my $collect = Venus::Collect->new(value => {1..8});

  my $execute = $collect->execute(sub{$_%6==0 ? (@_) : ()});

  # {5,6}

=back

=over 4

=item execute example 11

  package main;

  use Venus::Collect;
  use Venus::Array;

  my $value = Venus::Array->new([1..4]);

  my $collect = Venus::Collect->new(value => $value);

  my $execute = $collect->execute;

  # bless({value => [1..4], 'Venus::Array')

=back

=over 4

=item execute example 12

  package main;

  use Venus::Collect;
  use Venus::Array;

  my $value = Venus::Array->new([1..4]);

  my $collect = Venus::Collect->new(value => $value);

  my $execute = $collect->execute(sub{});

  # bless({value => [], 'Venus::Array')

=back

=over 4

=item execute example 13

  package main;

  use Venus::Collect;
  use Venus::Array;

  my $value = Venus::Array->new([1..4]);

  my $collect = Venus::Collect->new(value => $value);

  my $execute = $collect->execute(sub{$_});

  # bless({value => [], 'Venus::Array')

=back

=over 4

=item execute example 14

  package main;

  use Venus::Collect;
  use Venus::Array;

  my $value = Venus::Array->new([1..4]);

  my $collect = Venus::Collect->new(value => $value);

  my $execute = $collect->execute(sub{@_});

  # bless({value => [1..4], 'Venus::Array')

=back

=over 4

=item execute example 15

  package main;

  use Venus::Collect;
  use Venus::Array;

  my $value = Venus::Array->new([1..4]);

  my $collect = Venus::Collect->new(value => $value);

  my $execute = $collect->execute(sub{$_%2==0 ? (@_) : ()});

  # bless({value => [2,4], 'Venus::Array')

=back

=over 4

=item execute example 16

  package main;

  use Venus::Collect;
  use Venus::Set;

  my $value = Venus::Set->new([1..4]);

  my $collect = Venus::Collect->new(value => $value);

  my $execute = $collect->execute;

  # bless({value => [1..4], 'Venus::Set')

=back

=over 4

=item execute example 17

  package main;

  use Venus::Collect;
  use Venus::Set;

  my $value = Venus::Set->new([1..4]);

  my $collect = Venus::Collect->new(value => $value);

  my $execute = $collect->execute(sub{});

  # bless({value => [], 'Venus::Set')

=back

=over 4

=item execute example 18

  package main;

  use Venus::Collect;
  use Venus::Set;

  my $value = Venus::Set->new([1..4]);

  my $collect = Venus::Collect->new(value => $value);

  my $execute = $collect->execute(sub{$_});

  # bless({value => [], 'Venus::Set')

=back

=over 4

=item execute example 19

  package main;

  use Venus::Collect;
  use Venus::Set;

  my $value = Venus::Set->new([1..4]);

  my $collect = Venus::Collect->new(value => $value);

  my $execute = $collect->execute(sub{@_});

  # bless({value => [1..4], 'Venus::Set')

=back

=over 4

=item execute example 20

  package main;

  use Venus::Collect;
  use Venus::Set;

  my $value = Venus::Set->new([1..4]);

  my $collect = Venus::Collect->new(value => $value);

  my $execute = $collect->execute(sub{$_%2==0 ? (@_) : ()});

  # bless({value => [2,4], 'Venus::Set')

=back

=over 4

=item execute example 21

  package main;

  use Venus::Collect;
  use Venus::Hash;

  my $value = Venus::Hash->new(value => {1..8});

  my $collect = Venus::Collect->new(value => $value);

  my $execute = $collect->execute;

  # bless({value => {1..8}, 'Venus::Hash')

=back

=over 4

=item execute example 22

  package main;

  use Venus::Collect;
  use Venus::Hash;

  my $value = Venus::Hash->new(value => {1..8});

  my $collect = Venus::Collect->new(value => $value);

  my $execute = $collect->execute(sub{});

  # bless({value => {}, 'Venus::Hash')

=back

=over 4

=item execute example 23

  package main;

  use Venus::Collect;
  use Venus::Hash;

  my $value = Venus::Hash->new(value => {1..8});

  my $collect = Venus::Collect->new(value => $value);

  my $execute = $collect->execute(sub{$_});

  # bless({value => {}, 'Venus::Hash')

=back

=over 4

=item execute example 24

  package main;

  use Venus::Collect;
  use Venus::Hash;

  my $value = Venus::Hash->new(value => {1..8});

  my $collect = Venus::Collect->new(value => $value);

  my $execute = $collect->execute(sub{@_});

  # bless({value => {1..8}, 'Venus::Hash')

=back

=over 4

=item execute example 25

  package main;

  use Venus::Collect;
  use Venus::Hash;

  my $value = Venus::Hash->new(value => {1..8});

  my $collect = Venus::Collect->new(value => $value);

  my $execute = $collect->execute(sub{$_%6==0 ? (@_) : ()});

  # bless({value => {5,6}, 'Venus::Hash')

=back

=over 4

=item execute example 26

  package main;

  use Venus::Collect;
  use Venus::Map;

  my $value = Venus::Map->new(value => {1..8});

  my $collect = Venus::Collect->new(value => $value);

  my $execute = $collect->execute;

  # bless({value => {1..8}, 'Venus::Map')

=back

=over 4

=item execute example 27

  package main;

  use Venus::Collect;
  use Venus::Map;

  my $value = Venus::Map->new(value => {1..8});

  my $collect = Venus::Collect->new(value => $value);

  my $execute = $collect->execute(sub{});

  # bless({value => {}, 'Venus::Map')

=back

=over 4

=item execute example 28

  package main;

  use Venus::Collect;
  use Venus::Map;

  my $value = Venus::Map->new(value => {1..8});

  my $collect = Venus::Collect->new(value => $value);

  my $execute = $collect->execute(sub{$_});

  # bless({value => {}, 'Venus::Map')

=back

=over 4

=item execute example 29

  package main;

  use Venus::Collect;
  use Venus::Map;

  my $value = Venus::Map->new(value => {1..8});

  my $collect = Venus::Collect->new(value => $value);

  my $execute = $collect->execute(sub{@_});

  # bless({value => {1..8}, 'Venus::Map')

=back

=over 4

=item execute example 30

  package main;

  use Venus::Collect;
  use Venus::Map;

  my $value = Venus::Map->new(value => {1..8});

  my $collect = Venus::Collect->new(value => $value);

  my $execute = $collect->execute(sub{$_%6==0 ? (@_) : ()});

  # bless({value => {5,6}, 'Venus::Map')

=back

=over 4

=item execute example 31

  package main;

  use Venus::Collect;

  my $value = bless [1..4], 'Example';

  my $collect = Venus::Collect->new(value => $value);

  my $execute = $collect->execute;

  # bless([1..4], 'Example')

=back

=over 4

=item execute example 32

  package main;

  use Venus::Collect;

  my $value = bless [1..4], 'Example';

  my $collect = Venus::Collect->new(value => $value);

  my $execute = $collect->execute(sub{});

  # bless([], 'Example')

=back

=over 4

=item execute example 33

  package main;

  use Venus::Collect;

  my $value = bless [1..4], 'Example';

  my $collect = Venus::Collect->new(value => $value);

  my $execute = $collect->execute(sub{$_});

  # bless([], 'Example')

=back

=over 4

=item execute example 34

  package main;

  use Venus::Collect;

  my $value = bless [1..4], 'Example';

  my $collect = Venus::Collect->new(value => $value);

  my $execute = $collect->execute(sub{@_});

  # bless([1..4], 'Example')

=back

=over 4

=item execute example 35

  package main;

  use Venus::Collect;

  my $value = bless [1..4], 'Example';

  my $collect = Venus::Collect->new(value => $value);

  my $execute = $collect->execute(sub{$_%2==0 ? (@_) : ()});

  # bless([2,4], 'Example')

=back

=over 4

=item execute example 36

  package main;

  use Venus::Collect;

  my $value = bless {1..8}, 'Example';

  my $collect = Venus::Collect->new(value => $value);

  my $execute = $collect->execute;

  # bless({1..8}, 'Example')

=back

=over 4

=item execute example 37

  package main;

  use Venus::Collect;

  my $value = bless {1..8}, 'Example';

  my $collect = Venus::Collect->new(value => $value);

  my $execute = $collect->execute(sub{});

  # bless({}, 'Example')

=back

=over 4

=item execute example 38

  package main;

  use Venus::Collect;

  my $value = bless {1..8}, 'Example';

  my $collect = Venus::Collect->new(value => $value);

  my $execute = $collect->execute(sub{$_});

  # bless({}, 'Example')

=back

=over 4

=item execute example 39

  package main;

  use Venus::Collect;

  my $value = bless {1..8}, 'Example';

  my $collect = Venus::Collect->new(value => $value);

  my $execute = $collect->execute(sub{@_});

  # bless({1..8}, 'Example')

=back

=over 4

=item execute example 40

  package main;

  use Venus::Collect;

  my $value = bless {1..8}, 'Example';

  my $collect = Venus::Collect->new(value => $value);

  my $execute = $collect->execute(sub{$_%6==0 ? (@_) : ()});

  # bless({5,6}, 'Example')

=back

=cut

=head2 new

  new(any @args) (Venus::Collect)

The new method returns a new instance.

I<Since C<4.15>>

=over 4

=item new example 1

  package main;

  use Venus::Collect;

  my $new = Venus::Collect->new;

  # bless({value => undef}, 'Venus::Collect')

=back

=over 4

=item new example 2

  package main;

  use Venus::Collect;

  my $new = Venus::Collect->new([1..4]);

  # bless({value => [1..4]}, 'Venus::Collect')

=back

=over 4

=item new example 3

  package main;

  use Venus::Collect;

  my $new = Venus::Collect->new(value => [1..4]);

  # bless({value => [1..4]}, 'Venus::Collect')

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