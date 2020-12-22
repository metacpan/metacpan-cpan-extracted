package Zing::Logic::Watcher;

use 5.014;

use strict;
use warnings;

use registry 'Zing::Types';
use routines;

use Data::Object::Class;
use Data::Object::ClassHas;

extends 'Zing::Logic';

use Zing::Flow;
use Zing::Fork;

our $VERSION = '0.20'; # VERSION

# ATTRIBUTES

has 'fork' => (
  is => 'ro',
  isa => 'Fork',
  new => 1
);

fun new_fork($self) {
  Zing::Fork->new(parent => $self->process, scheme => $self->scheme)
}

has 'on_launch' => (
  is => 'ro',
  isa => 'CodeRef',
  new => 1,
);

fun new_on_launch($self) {
  $self->can('handle_launch_event')
}

has 'on_monitor' => (
  is => 'ro',
  isa => 'CodeRef',
  new => 1,
);

fun new_on_monitor($self) {
  $self->can('handle_monitor_event')
}

has 'on_sanitize' => (
  is => 'ro',
  isa => 'CodeRef',
  new => 1,
);

fun new_on_sanitize($self) {
  $self->can('handle_sanitize_event')
}

has 'scheme' => (
  is => 'ro',
  isa => 'Scheme',
  new => 1
);

fun new_scheme($self) {
  $self->process->scheme
}

has 'size' => (
  is => 'ro',
  isa => 'Int',
  new => 1
);

fun new_size($self) {
  $self->scheme->[2]
}

# METHODS

method flow() {
  my $step_0 = $self->next::method;

  my $step_1 = Zing::Flow->new(
    name => 'on_launch',
    code => fun($step, $loop) { $self->trace('on_launch')->($self) }
  );
  my $step_2 = $step_1->next(Zing::Flow->new(
    name => 'on_monitor',
    code => fun($step, $loop) { $self->trace('on_monitor')->($self) }
  ));
  my $step_3 = $step_2->next(Zing::Flow->new(
    name => 'on_sanitize',
    code => fun($step, $loop) { $self->trace('on_sanitize')->($self) }
  ));

  $step_0->append($step_1);
  $step_0
}

method handle_launch_event() {
  my $fork = $self->fork;
  my $process = $self->process;

  if ($self->interupt) {
    return 0;
  }

  if ($process->loop->last) {
    return 0;
  }

  if ($process->loop->stop) {
    return 0;
  }

  my $max_forks = $self->size;
  my $has_forks = keys %{$fork->processes};

  if ($has_forks > $max_forks) {
    return 0; # wtf
  }
  if (my $needs = $max_forks - $has_forks) {
    for (1..$needs) {
      $fork->execute;
    }
  }
  else {
    return 0;
  }
}

method handle_monitor_event() {
  my $fork = $self->fork;

  return $fork->monitor;
}

method handle_sanitize_event() {
  my $fork = $self->fork;

  return $fork->sanitize;
}

method signals() {
  my $trapped = {};
  my $fork = $self->fork;

  $trapped->{INT} = sub {
    $self->trace('interupt', 'INT');
    $fork->terminate($self->interupt);
    do {0} while ($fork->sanitize); # reap children
    $self->process->winddown;
  };

  $trapped->{QUIT} = sub {
    $self->trace('interupt', 'QUIT');
    $fork->terminate($self->interupt);
    do {0} while ($fork->sanitize); # reap children
    $self->process->winddown;
  };

  $trapped->{TERM} = sub {
    $self->trace('interupt', 'TERM');
    $fork->terminate($self->interupt);
    do {0} while ($fork->sanitize); # reap children
    $self->process->winddown;
  };

  $trapped->{USR1} = sub {
    $self->note('handles "interupt", with, USR1');
    $fork->terminate('INT');
    do {0} while ($fork->sanitize); # reap children
  };

  $trapped->{USR2} = sub {
    $self->note('handles "interupt", with, USR2');
    $fork->terminate('INT');
    do {0} while ($fork->sanitize); # reap children
  };

  return $trapped;
}

1;

=encoding utf8

=head1 NAME

Zing::Logic::Watcher - Watcher Logic

=cut

=head1 ABSTRACT

Watcher Process Logic Chain

=cut

=head1 SYNOPSIS

  package Process;

  use parent 'Zing::Process';

  sub scheme {
    ['MyApp', [], 1]
  }

  package main;

  use Zing::Logic::Watcher;

  my $logic = Zing::Logic::Watcher->new(process => Process->new);

  # $logic->execute;

=cut

=head1 DESCRIPTION

This package provides the logic (or logic chain) to be executed by the watcher
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

=head2 fork

  fork(Fork)

This attribute is read-only, accepts C<(Fork)> values, and is optional.

=cut

=head2 interupt

  interupt(Interupt)

This attribute is read-only, accepts C<(Interupt)> values, and is optional.

=cut

=head2 on_launch

  on_launch(CodeRef)

This attribute is read-only, accepts C<(CodeRef)> values, and is optional.

=cut

=head2 on_monitor

  on_monitor(CodeRef)

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

=head2 on_sanitize

  on_sanitize(CodeRef)

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

=head2 scheme

  scheme(Scheme)

This attribute is read-only, accepts C<(Scheme)> values, and is optional.

=cut

=head2 size

  size(Int)

This attribute is read-only, accepts C<(Int)> values, and is optional.

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
