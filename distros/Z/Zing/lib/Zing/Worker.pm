package Zing::Worker;

use 5.014;

use strict;
use warnings;

use registry 'Zing::Types';
use routines;

use Data::Object::Class;
use Data::Object::ClassHas;

use Zing::Logic::Worker;

extends 'Zing::Process';

our $VERSION = '0.27'; # VERSION

# ATTRIBUTES

has 'on_handle' => (
  is => 'ro',
  isa => 'Maybe[CodeRef]',
  opt => 1,
);

has 'on_queues' => (
  is => 'ro',
  isa => 'Maybe[CodeRef]',
  opt => 1,
);

# BUILDERS

fun new_logic($self) {
  my $debug = $self->env->debug;
  Zing::Logic::Worker->new(debug => $debug, process => $self)
}

# METHODS

method handle(@args) {
  return $self if !$self->on_handle;

  my $handled = $self->on_handle->($self, @args);

  return $handled;
}

method queues(@args) {
  return $self if !$self->on_queues;

  my $queues = $self->on_queues->($self, @args);

  return $queues;
}

1;



=encoding utf8

=head1 NAME

Zing::Worker - Worker Process

=cut

=head1 ABSTRACT

Worker Process

=cut

=head1 SYNOPSIS

  package MyApp;

  use parent 'Zing::Worker';

  sub handle {
    my ($name, $data) = @_;

    [$name, $data];
  }

  sub perform {
    time;
  }

  sub queues {
    ['todos'];
  }

  sub receive {
    my ($self, $from, $data) = @_;

    [$from, $data];
  }

  package main;

  my $myapp = MyApp->new;

  # $myapp->execute;

=cut

=head1 DESCRIPTION

This package provides a L<Zing::Process> which listens to one or more queues
calls the C<handle> method for each new message received. The standard process
C<perform> and C<receive> methods operate as expected.

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Zing::Process>

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Zing::Types>

=cut

=head1 SCENARIOS

This package supports the following scenarios:

=cut

=head2 handle

  # given: synopsis

  $myapp->handle('todos', { todo => 'rebuild' });

The handle method is meant to be implemented by a subclass and is
automatically invoked when a message is received from a defined queue.

=cut

=head2 perform

  # given: synopsis

  $myapp->perform;

The perform method is meant to be implemented by a subclass and is
automatically invoked iteratively by the event-loop.

=cut

=head2 queues

  # given: synopsis

  $myapp->queues;

The queues method is meant to be implemented by a subclass and is automatically
invoked when the process is executed.

=cut

=head2 receive

  # given: synopsis

  $myapp->receive($myapp->name, { status => 'ok' });

The receive method is meant to be implemented by a subclass and is
automatically invoked iteratively by the event-loop.

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 on_handle

  on_handle(Maybe[CodeRef])

This attribute is read-only, accepts C<(Maybe[CodeRef])> values, and is optional.

=cut

=head2 on_queues

  on_queues(Maybe[CodeRef])

This attribute is read-only, accepts C<(Maybe[CodeRef])> values, and is optional.

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 handle

  handle(Str $queue, HashRef $data) : Any

The handle method, when not overloaded, executes the callback in the
L</on_handle> attribute for each new message available in any of the queues
delcared.

=over 4

=item handle example #1

  my $worker = Zing::Worker->new(
    on_handle => sub {
      my ($self, $queue, $data) = @_;
      [$queue, $data];
    },
  );

  $worker->handle('todos', {});

=back

=cut

=head2 queues

  queues(Any @args) : ArrayRef[Str]

The queues method, when not overloaded, executes the callback in the
L</on_queues> attribute and expects a list of named queues to be processed.

=over 4

=item queues example #1

  my $worker = Zing::Worker->new(
    on_queues => sub {
      ['todos'];
    },
  );

  $worker->queues;

=back

=over 4

=item queues example #2

  my $worker = Zing::Worker->new(
    on_queues => sub {
      my ($self, @queues) = @_;
      [@queues, 'other'];
    },
  );

  $worker->queues('todos-p1', 'todos-p2', 'todos-p3');

=back

=cut

=head1 AUTHOR

Al Newkirk, C<awncorp@cpan.org>

=head1 LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the terms
of the The Apache License, Version 2.0, as elucidated in the L<"license
file"|https://github.com/cpanery/zing/blob/master/LICENSE>.

=head1 PROJECT

L<Wiki|https://github.com/cpanery/zing/wiki>

L<Project|https://github.com/cpanery/zing>

L<Initiatives|https://github.com/cpanery/zing/projects>

L<Milestones|https://github.com/cpanery/zing/milestones>

L<Contributing|https://github.com/cpanery/zing/blob/master/CONTRIBUTE.md>

L<Issues|https://github.com/cpanery/zing/issues>

=cut
