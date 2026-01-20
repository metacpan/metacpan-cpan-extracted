package Venus::Role::Boxable;

use 5.018;

use strict;
use warnings;

# IMPORTS

use Venus::Role 'with';

# METHODS

sub box {
  my ($self, $method, @args) = @_;

  require Venus::Box;

  local $_ = $self;

  my $value = $method ? $self->$method(@args) : $self;

  return Venus::Box->new(value => $value);
}

sub boxed {
  my ($self, @args) = @_;

  return $self->box(@args)->unbox;
}

# EXPORTS

sub EXPORT {
  ['box', 'boxed']
}

1;



=head1 NAME

Venus::Role::Boxable - Boxable Role

=cut

=head1 ABSTRACT

Boxable Role for Perl 5

=cut

=head1 SYNOPSIS

  package Example;

  use Venus::Class;

  with 'Venus::Role::Boxable';

  attr 'text';

  package main;

  my $example = Example->new(text => 'hello, world');

  # $example->box('text')->lc->ucfirst->concat('.')->unbox->get;

  # "Hello, world."

=cut

=head1 DESCRIPTION

This package modifies the consuming package and provides a method for boxing
itself. This makes it possible to chain method calls across objects and values.

=cut

=head1 METHODS

This package provides the following methods:

=cut

=head2 box

  box(string | coderef $method, any @args) (object)

The box method returns the invocant boxed, i.e. encapsulated, using
L<Venus::Box>. This method supports dispatching, i.e. providing a method name
and arguments whose return value will be acted on by this method.

I<Since C<0.01>>

=over 4

=item box example 1

  package main;

  my $example = Example->new(text => 'hello, world');

  my $box = $example->box;

  # bless({ value => bless(..., "Example") }, "Venus::Box")

=back

=over 4

=item box example 2

  package main;

  my $example = Example->new(text => 'hello, world');

  my $box = $example->box('text');

  # bless({ value => bless(..., "Venus::String") }, "Venus::Box")

  # $example->box('text')->lc->ucfirst->concat('.')->unbox->get;

=back

=cut

=head2 boxed

  boxed(string | coderef $method, any @args) (object)

The boxed method dispatches to L</box> and returns the "unboxed" value. This
method supports dispatching, i.e. providing a method name and arguments whose
return value will be acted on by this method.

I<Since C<4.15>>

=over 4

=item boxed example 1

  # given: synopsis

  package main;

  my $boxed = $example->boxed;

  # bless(..., "Example")

=back

=over 4

=item boxed example 2

  # given: synopsis

  package main;

  my $boxed = $example->boxed('text');

  # bless({value => 'hello world'}, "Venus::String")

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