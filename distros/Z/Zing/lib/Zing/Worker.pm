package Zing::Worker;

use 5.014;

use strict;
use warnings;

use registry 'Zing::Types';
use routines;

use Data::Object::Class;
use Zing::Logic::Worker;

extends 'Zing::Process';

our $VERSION = '0.13'; # VERSION

# BUILDERS

fun new_logic($self) {
  Zing::Logic::Worker->new(process => $self)
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
