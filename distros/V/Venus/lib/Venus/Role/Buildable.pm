package Venus::Role::Buildable;

use 5.018;

use strict;
use warnings;

use Venus::Role 'with';

# BUILDERS

sub BUILD {
  my ($self, $args) = @_;

  if ($self->can('build_self')) {
    $self->build_self($args);
  }

  return $self;
}

sub BUILDARGS {
  my ($self, @args) = @_;

  # build_nil accepts a single-arg (empty hash)
  my $present = @args == 1 && ref $args[0] eq 'HASH' && !%{$args[0]};

  # empty hash argument
  if ($self->can('build_nil') && $present) {
    @args = ($self->build_nil($args[0]));
  }

  # build_arg accepts a single-arg (non-hash)
  my $inflate = @args == 1 && ref $args[0] ne 'HASH';

  # single argument
  if ($self->can('build_arg') && $inflate) {
    @args = ($self->build_arg($args[0]));
  }

  # build_args should not accept a single-arg (non-hash)
  my $ignore = @args == 1 && ref $args[0] ne 'HASH';

  # standard arguments
  if ($self->can('build_args') && !$ignore) {
    @args = ($self->build_args(@args == 1 ? $args[0] : {@args}));
  }

  return (@args);
}

# EXPORTS

sub EXPORT {
  ['BUILDARGS']
}

1;



=head1 NAME

Venus::Role::Buildable - Buildable Role

=cut

=head1 ABSTRACT

Buildable Role for Perl 5

=cut

=head1 SYNOPSIS

  package Example;

  use Venus::Class;

  with 'Venus::Role::Buildable';

  attr 'test';

  package main;

  my $example = Example->new;

  # $example->test;

=cut

=head1 DESCRIPTION

This package modifies the consuming package and provides methods for hooking
into object construction of the consuming class, e.g. handling single-arg
object construction.

=cut

=head1 METHODS

This package provides the following methods:

=cut

=head2 build_arg

  build_arg(any $data) (hashref)

The build_arg method, if defined, is only called during object construction
when a single non-hashref is provided.




I<Since C<0.01>>

=over 4

=item build_arg example 1

  package Example1;

  use Venus::Class;

  attr 'x';
  attr 'y';

  with 'Venus::Role::Buildable';

  sub build_arg {
    my ($self, $data) = @_;

    $data = { x => $data, y => $data };

    return $data;
  }

  package main;

  my $example = Example1->new(10);

  # $example->x;
  # $example->y;

=back

=cut

=head2 build_args

  build_args(hashref $data) (hashref)

The build_args method, if defined, is only called during object construction to
hook into the handling of the arguments provided.

I<Since C<0.01>>

=over 4

=item build_args example 1

  package Example2;

  use Venus::Class;

  attr 'x';
  attr 'y';

  with 'Venus::Role::Buildable';

  sub build_args {
    my ($self, $data) = @_;

    $data->{x} ||= int($data->{x} || 100);
    $data->{y} ||= int($data->{y} || 100);

    return $data;
  }

  package main;

  my $example = Example2->new(x => 10, y => 10);

  # $example->x;
  # $example->y;

=back

=cut

=head2 build_nil

  build_nil(hashref $data) (any)

The build_nil method, if defined, is only called during object construction
when a single empty hashref is provided.

I<Since C<0.01>>

=over 4

=item build_nil example 1

  package Example4;

  use Venus::Class;

  attr 'x';
  attr 'y';

  with 'Venus::Role::Buildable';

  sub build_nil {
    my ($self, $data) = @_;

    $data = { x => 10, y => 10 };

    return $data;
  }

  package main;

  my $example = Example4->new({});

  # $example->x;
  # $example->y;

=back

=cut

=head2 build_self

  build_self(hashref $data) (object)

The build_self method, if defined, is only called during object construction
after all arguments have been handled and set.

I<Since C<0.01>>

=over 4

=item build_self example 1

  package Example3;

  use Venus::Class;

  attr 'x';
  attr 'y';

  with 'Venus::Role::Buildable';

  sub build_self {
    my ($self, $data) = @_;

    die if !$self->x;
    die if !$self->y;

    return $self;
  }

  package main;

  my $example = Example3->new(x => 10, y => 10);

  # $example->x;
  # $example->y;

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