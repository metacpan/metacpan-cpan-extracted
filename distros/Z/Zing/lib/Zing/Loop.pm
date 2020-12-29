package Zing::Loop;

use 5.014;

use strict;
use warnings;

use registry 'Zing::Types';
use routines;

use Data::Object::Class;
use Data::Object::ClassHas;

our $VERSION = '0.22'; # VERSION

# ATTRIBUTES

has 'flow' => (
  is => 'rw',
  isa => 'Flow',
  req => 1,
);

has 'last' => (
  is => 'rw',
  isa => 'Bool',
  def => 0,
);

has 'stop' => (
  is => 'rw',
  isa => 'Bool',
  def => 0,
);

# METHODS

method execute(Any @args) {
  my $step = my $head = $self->flow;

  until ($self->stop) {
    $step->execute($self, @args);
    $step = $step->next || do {
      last if $self->last;
      $head;
    };
  }

  return $self;
}

method exercise(Any @args) {
  my $step = my $head = $self->flow;

  until (!$step) {
    $step->execute($self, @args);
    $step = $step->next;
    last if $self->stop;
  }

  return $self;
}

1;

=encoding utf8

=head1 NAME

Zing::Loop - Event Loop

=cut

=head1 ABSTRACT

Process Event Loop

=cut

=head1 SYNOPSIS

  use Zing::Flow;
  use Zing::Loop;

  my $loop = Zing::Loop->new(
    flow => Zing::Flow->new(name => 'init', code => sub {1})
  );

=cut

=head1 DESCRIPTION

This package provides represents the process event-loop, it is implemented as
an infinite loop which executes L<Zing::Flow> objects.

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Zing::Types>

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 flow

  flow(Flow)

This attribute is read-only, accepts C<(Flow)> values, and is required.

=cut

=head2 last

  last(Bool)

This attribute is read-only, accepts C<(Bool)> values, and is optional.

=cut

=head2 stop

  stop(Bool)

This attribute is read-only, accepts C<(Bool)> values, and is optional.

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 execute

  execute(Any @args) : Object

The execute method executes the event-loop indefinitely.

=over 4

=item execute example #1

  # given: synopsis

  $loop->execute;

=back

=cut

=head2 exercise

  exercise(Any @args) : Object

The exercise method executes the event-loop and stops after the first cycle.

=over 4

=item exercise example #1

  # given: synopsis

  $loop->exercise;

=back

=over 4

=item exercise example #2

  package Loop;

  our $i = 0;

  my $flow_0 = Zing::Flow->new(
    name => 'flow_0',
    code => sub {
      my ($flow, $loop) = @_; $loop->stop(1);
    }
  );
  my $flow_1 = $flow_0->next(Zing::Flow->new(
    name => 'flow_1',
    code => sub {
      my ($flow, $loop) = @_; $i++;
    }
  ));

  my $loop = Zing::Loop->new(flow => $flow_0);

  $loop->exercise;

=back

=over 4

=item exercise example #3

  package Loop;

  our $i = 0;

  my $flow_0 = Zing::Flow->new(
    name => 'flow_0',
    code => sub {
      my ($flow, $loop) = @_; $loop->last(1);
    }
  );
  my $flow_1 = $flow_0->next(Zing::Flow->new(
    name => 'flow_1',
    code => sub {
      my ($flow, $loop) = @_; $i++;
    }
  ));

  my $loop = Zing::Loop->new(flow => $flow_0);

  $loop->exercise;

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
