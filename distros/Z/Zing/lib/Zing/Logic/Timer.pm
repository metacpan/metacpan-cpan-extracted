package Zing::Logic::Timer;

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

use Time::Crontab;
use Time::Piece;

our $VERSION = '0.27'; # VERSION

# ATTRIBUTES

has 'on_timer' => (
  is => 'ro',
  isa => 'CodeRef',
  new => 1,
);

fun new_on_timer($self) {
  $self->can('handle_timer_event')
}

has 'schedules' => (
  is => 'ro',
  isa => 'ArrayRef[Schedule]',
  new => 1
);

fun new_schedules($self) {
  $self->process->schedules
}

has 'relays' => (
  is => 'ro',
  isa => 'HashRef[Queue]',
  new => 1
);

fun new_relays($self) {
  +{map {$_, Zing::Queue->new(name => $_)} map @{$$_[1]}, @{$self->schedules}}
}

# SHIMS

sub _tick {
  localtime->truncate(to => 'minute')->epoch
}

sub _time {
  CORE::time
}

# METHODS

method flow() {
  my $step_0 = $self->next::method;

  my $step_1 = Zing::Flow->new(
    name => 'on_timer',
    code => fun($step, $loop) { $self->trace('on_timer')->($self) }
  );

  $step_0->append($step_1);
  $step_0
}

my $aliases = {
  # at 00:00 on day-of-month 1 in january
  '@yearly' => '0 0 1 1 *',
  # at 00:00 on day-of-month 1 in january
  '@annually' => '0 0 1 1 *',
  # at 00:00 on day-of-month 1
  '@monthly' => '0 0 1 * *',
  # at 00:00 on monday
  '@weekly' => '0 0 * * 1',
  # at 00:00 on saturday
  '@weekend' => '0 0 * * 6',
  # at 00:00 every day
  '@daily' => '0 0 * * *',
  # at minute 0 every hour
  '@hourly' => '0 * * * *',
  # at every minute
  '@minute' => '* * * * *',
};

method handle_timer_event($name) {
  my $process = $self->process;

  my $_tick = _tick;
  my $_time = _time;

  for (my $i = 0; $i < @{$self->schedules}; $i++) {
    # run each schedule initially, and then once per minute
    next if $_tick == (
      $self->{tick}[$i] || 0
    );

    # unpack schedule
    my $schedule = $self->schedules->[$i];
    my $frequency = $schedule->[0] || '';
    my $cronexpr = $aliases->{$frequency} || $frequency;
    my $queues = $schedule->[1];
    my $message = $schedule->[2];

    # cached crontab object
    my $cron = $self->{cron}[$i] ||= Time::Crontab->new($cronexpr);

    # next unless our times is here!
    next unless $cron->match($_time);

    # record tick for once-per-minute excution
    $self->{tick}[$i] = $_tick;

    # deliver messages to queues
    for my $name (@$queues) {
      $self->relays->{$name}->send($message);
    }
  }

  return $self;
}

1;



=encoding utf8

=head1 NAME

Zing::Logic::Timer - Timer Logic

=cut

=head1 ABSTRACT

Timer Process Logic Chain

=cut

=head1 SYNOPSIS

  package Process;

  use parent 'Zing::Process';

  sub schedules {
    [['@minute', ['tasks'], { do => 1 }]]
  }

  package main;

  use Zing::Logic::Timer;

  my $logic = Zing::Logic::Timer->new(process => Process->new);

  # $logic->execute;

=cut

=head1 DESCRIPTION

This package provides the logic (or logic chain) to be executed by the timer
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

=head2 on_timer

  on_timer(CodeRef)

This attribute is read-only, accepts C<(CodeRef)> values, and is optional.

=cut

=head2 process

  process(Process)

This attribute is read-only, accepts C<(Process)> values, and is required.

=cut

=head2 relays

  relays(HashRef[Queue])

This attribute is read-only, accepts C<(HashRef[Queue])> values, and is optional.

=cut

=head2 schedules

  schedules(ArrayRef[Schedule])

This attribute is read-only, accepts C<(ArrayRef[Schedule])> values, and is optional.

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
file"|https://github.com/cpanery/zing/blob/master/LICENSE>.

=head1 PROJECT

L<Wiki|https://github.com/cpanery/zing/wiki>

L<Project|https://github.com/cpanery/zing>

L<Initiatives|https://github.com/cpanery/zing/projects>

L<Milestones|https://github.com/cpanery/zing/milestones>

L<Contributing|https://github.com/cpanery/zing/blob/master/CONTRIBUTE.md>

L<Issues|https://github.com/cpanery/zing/issues>

=cut
