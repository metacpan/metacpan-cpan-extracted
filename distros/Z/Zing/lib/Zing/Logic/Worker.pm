package Zing::Logic::Worker;

use 5.014;

use strict;
use warnings;

use registry 'Zing::Types';
use routines;

use Data::Object::Class;
use Data::Object::ClassHas;

extends 'Zing::Logic';

use Zing::Flow;
use Zing::Queue;

our $VERSION = '0.20'; # VERSION

# ATTRIBUTES

has 'on_handle' => (
  is => 'ro',
  isa => 'CodeRef',
  new => 1,
);

fun new_on_handle($self) {
  $self->can('handle_handle_event')
}

has 'queues' => (
  is => 'ro',
  isa => 'ArrayRef[Str]',
  new => 1
);

fun new_queues($self) {
  $self->process->queues
}

has 'relays' => (
  is => 'ro',
  isa => 'HashRef[Queue]',
  new => 1
);

fun new_relays($self) {
  +{map {$_, Zing::Queue->new(name => $_)} @{$self->queues}}
}

# METHODS

method flow() {
  my $step_0 = $self->next::method;

  my ($step_f, $step_l);

  for my $name (@{$self->queues}) {
    my $label = $name =~ s/\W+/_/gr;
    my $step_x = Zing::Flow->new(
      name => "on_handle_${label}",
      code => fun($step, $loop) { $self->trace('on_handle')->($self, $name) },
    );
    $step_l->next($step_x) if $step_l;
    $step_l = $step_x;
    $step_f = $step_l if !$step_f;
  }

  $step_0->append($step_f) if $step_f;
  $step_0
}

method handle_handle_event($name) {
  my $process = $self->process;

  return unless $process->can('handle');

  my $data = $self->relays->{$name}->recv or return;

  $process->handle($name, $data);

  return $data;
}

1;

=encoding utf8

=head1 NAME

Zing::Logic::Worker - Worker Logic

=cut

=head1 ABSTRACT

Worker Process Logic Chain

=cut

=head1 SYNOPSIS

  package Process;

  use parent 'Zing::Process';

  sub queues {
    ['tasks']
  }

  package main;

  use Zing::Logic::Worker;

  my $logic = Zing::Logic::Worker->new(process => Process->new);

  # $logic->execute;

=cut

=head1 DESCRIPTION

This package provides the logic (or logic chain) to be executed by the worker
process event-loop.

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Zing::Logic>

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Zing::Types>

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 interupt

  interupt(Interupt)

This attribute is read-only, accepts C<(Interupt)> values, and is optional.

=cut

=head2 on_handle

  on_handle(CodeRef)

This attribute is read-only, accepts C<(CodeRef)> values, and is optional.

=cut

=head2 on_perform

  on_perform(CodeRef)

This attribute is read-only, accepts C<(CodeRef)> values, and is optional.

=cut

=head2 on_receive

  on_receive(CodeRef)

This attribute is read-only, accepts C<(CodeRef)> values, and is optional.

=cut

=head2 on_register

  on_register(CodeRef)

This attribute is read-only, accepts C<(CodeRef)> values, and is optional.

=cut

=head2 on_reset

  on_reset(CodeRef)

This attribute is read-only, accepts C<(CodeRef)> values, and is optional.

=cut

=head2 on_suicide

  on_suicide(CodeRef)

This attribute is read-only, accepts C<(CodeRef)> values, and is optional.

=cut

=head2 process

  process(Process)

This attribute is read-only, accepts C<(Process)> values, and is required.

=cut

=head2 queues

  queues(ArrayRef[Str])

This attribute is read-only, accepts C<(ArrayRef[Str])> values, and is optional.

=cut

=head2 relays

  relays(HashRef[Queue])

This attribute is read-only, accepts C<(HashRef[Queue])> values, and is optional.

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 flow

  flow() : Flow

The flow method builds and returns the logic flow for the process event-loop.

=over 4

=item flow example #1

  # given: synopsis

  my $flow = $logic->flow;

=back

=cut

=head2 signals

  signals() : HashRef

The signals method builds and returns the process signal handlers.

=over 4

=item signals example #1

  # given: synopsis

  my $signals = $logic->signals;

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
