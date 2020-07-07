package Zing::Ring;

use 5.014;

use strict;
use warnings;

use registry 'Zing::Types';
use routines;

use Data::Object::Class;
use Data::Object::ClassHas;

extends 'Zing::Process';

our $VERSION = '0.12'; # VERSION

# ATTRIBUTES

has 'processes' => (
  is => 'ro',
  isa => 'ArrayRef[Process]',
  req => 1
);

# METHODS

method destroy() {
  $_->destroy for @{$self->processes};

  return $self->next::method;
}

method execute() {
  $_->started(time) for @{$self->processes};

  $self->next::method;

  $_->destroy->stopped(time) for @{$self->processes};

  return $self;
}

method exercise() {
  $_->started(time) for @{$self->processes};

  $self->next::method;

  $_->destroy->stopped(time) for @{$self->processes};

  return $self;
}

method perform() {
  my $position = ($self->{position} ||= 0)++;

  my $process = $self->processes->[$position];

  $process->loop->exercise($process);

  delete $self->{position} if ($self->{position} + 1) > @{$self->processes};

  return $self;
}

method shutdown() {
  $_->shutdown for @{$self->processes};

  return $self->next::method;
}

method winddown() {
  $_->winddown for @{$self->processes};

  return $self->next::method;
}

1;

=encoding utf8

=head1 NAME

Zing::Ring - Process Ring

=cut

=head1 ABSTRACT

Multi-Process Assembly Ring

=cut

=head1 SYNOPSIS

  use Zing::Ring;
  use Zing::Process;

  my $ring = Zing::Ring->new(processes => [
    Zing::Process->new,
    Zing::Process->new,
  ]);

  # $ring->execute;

=cut

=head1 DESCRIPTION

This package provides a mechanism for joining two (or more) processes and
executes them as one in a turn-based manner.

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Zing::Process>

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Zing::Types>

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 processes

  processes(ArrayRef[Process])

This attribute is read-only, accepts C<(ArrayRef[Process])> values, and is required.

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 destroy

  destroy() : Object

The destroy method executes the C<destroy> method of all the processes in the
list.

=over 4

=item destroy example #1

  # given: synopsis

  [$ring, $ring->destroy]

=back

=cut

=head2 perform

  perform() : Any

The perform method executes the event-loop of the next process in the list with
each call.

=over 4

=item perform example #1

  # given: synopsis

  [$ring, $ring->perform]

=back

=cut

=head2 shutdown

  shutdown() : Object

The shutdown method executes the C<shutdown> method of all the processes in the
list.

=over 4

=item shutdown example #1

  # given: synopsis

  [$ring, $ring->shutdown]

=back

=cut

=head2 winddown

  winddown() : Object

The winddown method executes the C<winddown> method of all the processes in the
list.

=over 4

=item winddown example #1

  # given: synopsis

  [$ring, $ring->winddown]

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
