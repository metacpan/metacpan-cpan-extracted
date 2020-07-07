package Zing::Fork;

use 5.014;

use strict;
use warnings;

use registry 'Zing::Types';
use routines;

use Data::Object::Class;
use Data::Object::ClassHas;
use Data::Object::Space;

use POSIX ();

use Config;

our $VERSION = '0.12'; # VERSION

# ATTRIBUTES

has 'scheme' => (
  is => 'ro',
  isa => 'Scheme',
  req => 1,
);

has 'parent' => (
  is => 'rw',
  isa => 'Process',
  req => 1,
);

has 'processes' => (
  is => 'rw',
  isa => 'HashRef[Process]',
  def => sub{{}},
);

has 'space' => (
  is => 'ro',
  isa => 'Space',
  new => 1
);

fun new_space($self) {
  Data::Object::Space->new($self->scheme->[0])
}

# SHIMS

sub _waitpid {
  CORE::waitpid(shift, POSIX::WNOHANG)
}

# METHODS

method execute() {
  my $pid;
  my $process;
  my $sid = $$;

  if ($Config{d_pseudofork}) {
    Carp::confess "Error on fork: fork emulation not supported";
  }

  if(!defined($pid = fork)) {
    Carp::confess "Error on fork: $!";
  }

  # parent
  if ($pid) {
    $process = $self->space->load->new(
      @{$self->scheme->[1]},
      node => Zing::Node->new(pid => $pid),
      parent => $self->parent,
    );
    return $self->processes->{$pid} = $process;
  }
  # child
  else {
    $pid = $$;
    $process = $self->space->reload->new(
      @{$self->scheme->[1]},
      node => Zing::Node->new(pid => $pid),
      parent => $self->parent,

    );
    $process->execute;
  }

  POSIX::_exit(0);
}

method monitor() {
  my $result = {};

  for my $pid (sort keys %{$self->processes}) {
    $result->{$pid} = _waitpid $pid;
  }

  return $result;
}

method sanitize() {
  my $result = $self->monitor;

  for my $pid (sort keys %{$result}) {
    if ($result->{$pid} == $pid || $result->{$pid} == -1) {
      delete $self->processes->{$pid};
    }
  }

  return scalar(keys %{$self->processes});
}

method terminate(Str $signal = 'kill') {
  my $result = {};

  for my $pid (sort keys %{$self->processes}) {
    $result->{$pid} = $self->processes->{$pid}->signal($pid, $signal);
  }

  return $result;
}

1;

=encoding utf8

=head1 NAME

Zing::Fork - Fork Manager

=cut

=head1 ABSTRACT

Scheme Fork Manager

=cut

=head1 SYNOPSIS

  use Zing::Fork;
  use Zing::Process;

  my $scheme = ['MyApp', [], 1];
  my $fork = Zing::Fork->new(scheme => $scheme, parent => Zing::Process->new);

  # $fork->execute;

=cut

=head1 DESCRIPTION

This package provides provides a mechanism for forking and tracking processes,
as well as establishing the parent-child relationship. B<Note:> The C<$num>
part of the application scheme, i.e. C<['MyApp', [], $num]>, is ignored and
launching the desired forks requires calling L</execute> multiple times.

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Zing::Types>

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 parent

  parent(Process)

This attribute is read-only, accepts C<(Process)> values, and is required.

=cut

=head2 processes

  processes(HashRef[Process])

This attribute is read-only, accepts C<(HashRef[Process])> values, and is optional.

=cut

=head2 scheme

  scheme(Scheme)

This attribute is read-only, accepts C<(Scheme)> values, and is required.

=cut

=head2 space

  space(Space)

This attribute is read-only, accepts C<(Space)> values, and is optional.

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 execute

  execute() : Process

The execute method forks a process based on the scheme, adds it to the process
list and returns a representation of the child process.

=over 4

=item execute example #1

  # given: synopsis

  my $process = $fork->execute;

=back

=cut

=head2 monitor

  monitor() : HashRef[Int]

The monitor method calls L<perlfunc/waitpid> on tracked processes and returns
the results as a pid/result map.

=over 4

=item monitor example #1

  # given: synopsis

  $fork->execute;
  $fork->execute;

  # forks still alive

  my $results = $fork->monitor;

  # { 1000 => 1000, ... }

=back

=over 4

=item monitor example #2

  # given: synopsis

  $fork->execute;
  $fork->execute;

  # forks are dead

  my $results = $fork->monitor;

  # { 1000 => -1, ... }

=back

=cut

=head2 sanitize

  sanitize() : Int

The sanitize method removes inactive child processes from the process list and
returns the number of processes remaining.

=over 4

=item sanitize example #1

  # given: synopsis

  $fork->execute; # dead
  $fork->execute; # dead

  my $results = $fork->sanitize; # 0

=back

=over 4

=item sanitize example #2

  # given: synopsis

  $fork->execute; # live
  $fork->execute; # dead

  my $results = $fork->sanitize; # 1

=back

=over 4

=item sanitize example #3

  # given: synopsis

  $fork->execute; # live
  $fork->execute; # live

  my $results = $fork->sanitize; # 2

=back

=cut

=head2 terminate

  terminate(Str $signal = 'kill') : HashRef[Int]

The terminate method call L<perlfunc/kill> and sends a signal to all tracked
processes and returns the results as a pid/result map.

=over 4

=item terminate example #1

  # given: synopsis

  $fork->execute;
  $fork->execute;

  my $results = $fork->terminate; # kill

=back

=over 4

=item terminate example #2

  # given: synopsis

  $fork->execute;
  $fork->execute;

  my $results = $fork->terminate('term');

=back

=over 4

=item terminate example #3

  # given: synopsis

  $fork->execute;
  $fork->execute;

  my $results = $fork->terminate('usr2');

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
