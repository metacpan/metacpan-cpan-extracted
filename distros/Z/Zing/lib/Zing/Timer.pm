package Zing::Timer;

use 5.014;

use strict;
use warnings;

use registry 'Zing::Types';
use routines;

use Data::Object::Class;
use Data::Object::ClassHas;

use Zing::Logic::Timer;

extends 'Zing::Process';

our $VERSION = '0.27'; # VERSION

# ATTRIBUTES

has 'on_schedules' => (
  is => 'ro',
  isa => 'Maybe[CodeRef]',
  opt => 1,
);

# BUILDERS

fun new_logic($self) {
  my $debug = $self->env->debug;
  Zing::Logic::Timer->new(debug => $debug, process => $self)
}

# METHODS

method schedules(@args) {
  return $self if !$self->on_schedules;

  my $schedules = $self->on_schedules->($self, @args);

  return $schedules;
}

1;



=encoding utf8

=head1 NAME

Zing::Timer - Timer Process

=cut

=head1 ABSTRACT

Timer Process

=cut

=head1 SYNOPSIS

  package MyApp;

  use parent 'Zing::Timer';

  sub schedules {
    [
      # every ten minutes
      ['*/10 * * * *', ['tasks'], { do => 1 }],
    ]
  }

  package main;

  my $myapp = MyApp->new;

  # $myapp->execute;

=cut

=head1 DESCRIPTION

This package provides a L<Zing::Process> which places pre-defined messages into
message queues based on time-based scehdules. It supports minute-level
resolution and functions similarly to a crontab (cron table).

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

=head2 schedules

  # given: synopsis

  $myapp->schedules;

  # schedule structure
  # [$interval, $queues, $message, $adjustment]

  # predefined intervals

  # @annually is at 00:00 on day-of-month 1 in january
  # @daily is at 00:00 every day
  # @hourly is at minute 0 every hour
  # @minute is at every minute
  # @monthly is at 00:00 on day-of-month 1
  # @weekend is at 00:00 on saturday
  # @weekly is at 00:00 on monday
  # @yearly is at 00:00 on day-of-month 1 in january

  # other schedule examples

  # every minute
  # ['* * * * *', ['tasks'], { do => 1 }]

  # every hour (on the half hour)
  # ['30 * * * *', ['tasks'], { do => 1 }]

  # every 15th minute
  # ['*/15 * * * *', ['tasks'], { do => 1 }]

The schedules method is meant to be implemented by a subclass and is
automatically invoked when the process is executed, it should return a list of
schedules. A single schedule takes the form of C<[$interval, $queues,
$message]> where C<$interval> is represented as a cron-expression or using one
of the predefined interval name, e.g. C<@yearly>, C<@annually>, C<@monthly>,
C<@weekly>, C<@weekend>, C<@daily>, C<@hourly>, or C<@minute>.

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 on_schedules

  on_schedules(Maybe[CodeRef])

This attribute is read-only, accepts C<(Maybe[CodeRef])> values, and is optional.

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 schedules

  schedules(Any @args) : ArrayRef[Schedule]

The schedules method, when not overloaded, executes the callback in the
L</on_schedules> attribute and expects a list of crontab schedules to be
processed.

=over 4

=item schedules example #1

  my $timer = Zing::Timer->new(
    on_schedules => sub {
      [['@hourly', ['tasks'], { do => 1 }]]
    },
  );

  $timer->schedules;

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
