package Venus::Role::Reflectable;

use 5.018;

use strict;
use warnings;

use Venus::Role 'with';

# METHODS

sub class {
  my ($self) = @_;

  return ref($self) || $self;
}

sub meta {
  my ($self) = @_;

  require Venus::Meta;

  return Venus::Meta->new(name => $self->class);
}

sub reify {
  my ($self, $method, @args) = @_;

  return $self->type($method, @args)->deduce;
}

sub space {
  my ($self) = @_;

  require Venus::Space;

  return Venus::Space->new($self->class);
}

sub type {
  my ($self, $method, @args) = @_;

  require Venus::Type;

  local $_ = $self;

  my $value = $method
    ? $self->$method(@args) : $self->can('value') ? $self->value : $self;

  return Venus::Type->new(value => $value);
}

# EXPORTS

sub EXPORT {
  ['class', 'meta', 'reify', 'space', 'type']
}

1;



=head1 NAME

Venus::Role::Reflectable - Reflectable Role

=cut

=head1 ABSTRACT

Reflectable Role for Perl 5

=cut

=head1 SYNOPSIS

  package Example;

  use Venus::Class;

  with 'Venus::Role::Reflectable';

  sub test {
    true
  }

  package main;

  my $example = Example->new;

  # $example->space;

=cut

=head1 DESCRIPTION

This package modifies the consuming package and provides methods for
introspecting the object and its underlying package.

=cut

=head1 METHODS

This package provides the following methods:

=cut

=head2 class

  class() (string)

The class method returns the class name for the given class or object.

I<Since C<0.01>>

=over 4

=item class example 1

  # given: synopsis;

  my $class = $example->class;

  # "Example"

=back

=cut

=head2 meta

  meta() (Venus::Meta)

The meta method returns a L<Venus::Meta> object for the given object.

I<Since C<1.23>>

=over 4

=item meta example 1

  # given: synopsis;

  my $meta = $example->meta;

  # bless({name => "Example"}, "Venus::Meta")

=back

=cut

=head2 reify

  reify(string | coderef $code, any @args) (object)

The reify method dispatches the method call or executes the callback and
returns the result as a value object.

I<Since C<1.23>>

=over 4

=item reify example 1

  # given: synopsis

  package main;

  my $reify = $example->reify;

  # bless({}, "Example")

=back

=over 4

=item reify example 2

  # given: synopsis

  package main;

  my $reify = $example->reify('class');

  # bless({value => "Example"}, "Venus::String")

=back

=over 4

=item reify example 3

  # given: synopsis

  package main;

  my $reify = $example->reify('test');

  # bless({value => 1}, "Venus::Boolean")

=back

=cut

=head2 space

  space() (Venus::Space)

The space method returns a L<Venus::Space> object for the given object.

I<Since C<0.01>>

=over 4

=item space example 1

  # given: synopsis;

  my $space = $example->space;

  # bless({ value => "Example" }, "Venus::Space")

=back

=cut

=head2 type

  type(string | coderef $code, any @args) (Venus::Type)

The type method dispatches the method call or executes the callback and returns
the result as a L<Venus::Type> object.

I<Since C<0.01>>

=over 4

=item type example 1

  # given: synopsis;

  my $type = $example->type;

  # bless({ value => bless({}, "Example") }, "Venus::Type")

=back

=over 4

=item type example 2

  # given: synopsis;

  my $type = $example->type('class');

  # bless({ value => "Example" }, "Venus::Type")

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