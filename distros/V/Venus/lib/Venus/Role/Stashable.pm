package Venus::Role::Stashable;

use 5.018;

use strict;
use warnings;

# IMPORTS

use Venus::Role 'mask';

# ATTRIBUTES

mask 'private';

# BUILDERS

sub BUILD {
  my ($self, $data) = @_;

  $self->private({}) if !$self->private;

  return $self;
};

# METHODS

sub stash {
  my ($self, $key, $value) = @_;

  return $self->private if !exists $_[1];

  return $self->private->{$key} if !exists $_[2];

  $self->private->{$key} = $value;

  return $value;
}

# EXPORTS

sub EXPORT {
  ['stash', 'private']
}

1;



=head1 NAME

Venus::Role::Stashable - Stashable Role

=cut

=head1 ABSTRACT

Stashable Role for Perl 5

=cut

=head1 SYNOPSIS

  package Example;

  use Venus::Class;

  with 'Venus::Role::Stashable';

  attr 'test';

  package main;

  my $example = Example->new(test => time);

  # $example->stash;

=cut

=head1 DESCRIPTION

This package modifies the consuming package and provides methods for stashing
data within the object. This role differs from L<Venus::Role::Encaseable> in
that it obsures the stash but its data is easily accessible without getters and
setters, whereas Encaseable provides getters and setters to help obscure the
private instance data.

=cut

=head1 METHODS

This package provides the following methods:

=cut

=head2 stash

  stash(any $key, any $value) (any)

The stash method is used to fetch and stash named values associated with the
object. Calling this method without arguments returns all values.

I<Since C<0.01>>

=over 4

=item stash example 1

  package main;

  my $example = Example->new(test => time);

  my $stash = $example->stash;

  # {}

=back

=over 4

=item stash example 2

  package main;

  my $example = Example->new(test => time);

  my $stash = $example->stash('test', {1..4});

  # { 1 => 2, 3 => 4 }

=back

=over 4

=item stash example 3

  package main;

  my $example = Example->new(test => time);

  my $stash = $example->stash('test');

  # undef

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