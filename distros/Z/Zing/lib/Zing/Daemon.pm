package Zing::Daemon;

use 5.014;

use strict;
use warnings;

use registry 'Zing::Types';
use routines;

use Data::Object::Class;
use Data::Object::ClassHas;

use Carp ();

use Config;
use File::Spec;
use POSIX;

our $VERSION = '0.10'; # VERSION

# ATTRIBUTES

has 'app' => (
  is => 'ro',
  isa => 'Zing',
  req => 1,
);

has 'name' => (
  is => 'ro',
  isa => 'Str',
  req => 1,
);

has 'log' => (
  is => 'ro',
  isa => 'Logger',
  new => 1,
);

fun new_log($self) {
  FlightRecorder->new(level => 'info')
}

has 'pid_dir' => (
  is => 'ro',
  isa => 'Str',
  new => 1,
);

fun new_pid_dir($self) {
  -w $ENV{ZING_PIDDIR} ? $ENV{ZING_PIDDIR} :
  -w $ENV{ZING_HOME} ? $ENV{ZING_HOME} :
  -w File::Spec->curdir ? File::Spec->curdir : File::Spec->tmpdir
}

has 'pid_file' => (
  is => 'ro',
  isa => 'Str',
  new => 1,
);

fun new_pid_file($self) {
  join '.', $self->name, 'pid'
}

has 'pid_path' => (
  is => 'ro',
  isa => 'Str',
  new => 1,
);

fun new_pid_path($self) {
  File::Spec->catfile($self->pid_dir, $self->pid_file)
}

# METHODS

method execute() {
  my $app = $self->app;
  my $file = $self->pid_path;

  if (-e $file) {
    $self->log->fatal("pid file exists: $file");
    return 1;
  }

  open(my $fh, ">", "$file") or do {
    $self->log->fatal("pid file error: $!");
    return 1;
  };

  my ($cnt, $err) = do {
    local $@;
    (eval{chmod(0644, $file)}, $@)
  };
  if ($err) {
    $self->log->fatal("pid file error: $err");
    return 1;
  }

  # launch app
  my $pid = $self->fork;
  my $name = $self->name;

  print $fh "$pid\n";
  close $fh;

  $self->log->info("app created: $name");
  $self->log->info("pid file created: $file");

  return 0;
}

method fork() {
  my $app = $self->app;

  if ($Config{d_pseudofork}) {
    Carp::confess "Error on fork: fork emulation not supported";
  }

  my $pid = fork;

  if (!defined $pid) {
    Carp::confess "Error on fork: $!";
  }
  elsif ($pid == 0) {
    $self->app->start; # child
    unlink $self->pid_path;
    POSIX::_exit(0);
  }

  return $pid;
}

method start() {
  exit($self->execute);
}

1;

=encoding utf8

=head1 NAME

Zing::Daemon - Process Daemon

=cut

=head1 ABSTRACT

Daemon Process Management

=cut

=head1 SYNOPSIS

  use Zing;
  use Zing::Daemon;

  my $scheme = ['MyApp', [], 1];
  my $daemon = Zing::Daemon->new(name => 'app', app => Zing->new(scheme => $scheme));

  # $daemon->start;

=cut

=head1 DESCRIPTION

This package provides the mechanisms for running a L<Zing> application as a
daemon process.

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Zing::Types>

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 app

  app(Zing)

This attribute is read-only, accepts C<(Zing)> values, and is required.

=cut

=head2 log

  log(Logger)

This attribute is read-only, accepts C<(Logger)> values, and is optional.

=cut

=head2 name

  name(Str)

This attribute is read-only, accepts C<(Str)> values, and is required.

=cut

=head2 pid_dir

  pid_dir(Str)

This attribute is read-only, accepts C<(Str)> values, and is optional.

=cut

=head2 pid_file

  pid_file(Str)

This attribute is read-only, accepts C<(Str)> values, and is optional.

=cut

=head2 pid_path

  pid_path(Str)

This attribute is read-only, accepts C<(Str)> values, and is optional.

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 execute

  execute() : Int

The execute method forks the application and creates a pid file under the
L</pid_path>.

=over 4

=item execute example #1

  # given: synopsis

  my $exit = $daemon->execute;

=back

=cut

=head2 fork

  fork() : Int

The fork method forks the application and returns a pid.

=over 4

=item fork example #1

  # given: synopsis

  my $pid = $daemon->fork;

=back

=cut

=head2 start

  start() : Any

The start method executes the application and exits the program with the proper
exit code.

=over 4

=item start example #1

  # given: synopsis

  $daemon->start;

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
