package Zing::Flow;

use 5.014;

use strict;
use warnings;

use registry 'Zing::Types';
use routines;

use Data::Object::Class;
use Data::Object::ClassHas;

our $VERSION = '0.26'; # VERSION

# ATTRIBUTES

has 'name' => (
  is => 'ro',
  isa => 'Str',
  req => 1,
);

has 'next' => (
  is => 'rw',
  isa => 'Flow',
  opt => 1,
);

has 'code' => (
  is => 'ro',
  isa => 'CodeRef',
  req => 1,
);

# METHODS

method append(Flow $flow) {
  $self->bottom->next($flow);

  return $self;
}

method bottom() {
  my $flow = $self;

  while (my $next = $flow->next) {
    $flow = $next;
  }

  return $flow;
}

method execute(Any @args) {
  return $self->code->($self, @args);
}

method prepend(Flow $flow) {
  $flow->bottom->next($self);

  return $flow;
}

1;
=encoding utf8

=head1 NAME

Zing::Flow - Loop Step

=cut

=head1 ABSTRACT

Event-Loop Logic Chain

=cut

=head1 SYNOPSIS

  use Zing::Flow;

  my $flow = Zing::Flow->new(name => 'step_1', code => sub {1});

  # $flow->execute;

=cut

=head1 DESCRIPTION

This package provides represents an event-loop step, it is implemented as a
simplified linked-list that allows other flows to be appended, prepended, and
injected easily, anywhere in the flow.

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Zing::Types>

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 code

  code(CodeRef)

This attribute is read-only, accepts C<(CodeRef)> values, and is required.

=cut

=head2 name

  name(Str)

This attribute is read-only, accepts C<(Str)> values, and is required.

=cut

=head2 next

  next(Flow)

This attribute is read-write, accepts C<(Flow)> values, and is optional.

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 append

  append(Flow $flow) : Flow

The append method appends the flow provided to the end of its chain.

=over 4

=item append example #1

  # given: synopsis

  my $next = Zing::Flow->new(name => 'step_2', code => sub {2});

  $flow->append($next);

=back

=cut

=head2 bottom

  bottom() : Flow

The bottom method returns the flow object at the end of its chain.

=over 4

=item bottom example #1

  # given: synopsis

  $flow->bottom;

=back

=over 4

=item bottom example #2

  # given: synopsis

  my $next = Zing::Flow->new(name => 'step_2', code => sub {2});

  $flow->next($next);

  $flow->bottom;

=back

=cut

=head2 execute

  execute(Any @args) : Any

The execute method executes its code routine as a method call.

=over 4

=item execute example #1

  # given: synopsis

  $flow->execute;

=back

=cut

=head2 prepend

  prepend(Flow $flow) : Flow

The prepend method prepends the flow provided by adding itself to the end of
that chain and returns the flow object provided.

=over 4

=item prepend example #1

  # given: synopsis

  my $base = Zing::Flow->new(name => 'step_0', code => sub {0});

  $flow->prepend($base);

=back

=cut

=head1 AUTHOR

Al Newkirk, C<awncorp@cpan.org>

=head1 LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the terms
of the The Apache License, Version 2.0, as elucidated in the L<"license
file"|https://github.com/iamalnewkirk/zing/blob/master/LICENSE>.

=head1 PROJECT

L<Wiki|https://github.com/iamalnewkirk/zing/wiki>

L<Project|https://github.com/iamalnewkirk/zing>

L<Initiatives|https://github.com/iamalnewkirk/zing/projects>

L<Milestones|https://github.com/iamalnewkirk/zing/milestones>

L<Contributing|https://github.com/iamalnewkirk/zing/blob/master/CONTRIBUTE.md>

L<Issues|https://github.com/iamalnewkirk/zing/issues>

=cut
