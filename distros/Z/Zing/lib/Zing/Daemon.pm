package Zing::Daemon;

use 5.014;

use strict;
use warnings;

use registry 'Zing::Types';
use routines;

use Data::Object::Class;
use Data::Object::ClassHas;

extends 'Zing::Entity';

use Config;
use File::Spec;
use FlightRecorder;
use POSIX;

our $VERSION = '0.26'; # VERSION

# ATTRIBUTES

has cartridge => (
  is => 'ro',
  isa => 'Cartridge',
  req => 1,
);

has logger => (
  is => 'ro',
  isa => 'Logger',
  new => 1,
);

fun new_logger($self) {
  $self->app->logger
}

has journal => (
  is => 'ro',
  isa => 'Journal',
  new => 1,
);

fun new_journal($self) {
  $self->app->journal(
    level => $self->log_level,
    verbose => $self->log_verbose,
  )
}

has kernel => (
  is => 'ro',
  isa => 'Zing',
  new => 1,
);

fun new_kernel($self) {
  $self->app->zing(scheme => $self->cartridge->scheme)
}

has log_filter_from => (
  is => 'ro',
  isa => 'Str',
  opt => 1,
);

has log_filter_queries => (
  is => 'ro',
  isa => 'ArrayRef[Str]',
  opt => 1,
);

has log_filter_tag => (
  is => 'ro',
  isa => 'Str',
  opt => 1,
);

has log_level => (
  is => 'ro',
  isa => 'Str',
  def => 'debug',
);

has log_reset => (
  is => 'ro',
  isa => 'Bool',
  def => 0,
);

has log_verbose => (
  is => 'ro',
  isa => 'Bool',
  def => 0,
);

# METHODS

method fork() {
  if ($Config{d_pseudofork}) {
    $self->throw(error_fork("emulation not supported"));
  }

  my $pid = fork;

  if (!defined $pid) {
    $self->throw(error_fork("$!"));
  }
  elsif ($pid == 0) {
    $self->throw(error_fork("terminal detach failed")) if POSIX::setsid() < 0;
    $self->kernel->start; # child
    unlink $self->cartridge->pidfile;
    POSIX::_exit(0);
  }

  return $pid;
}

method logs(CodeRef $callback) {
  my $journal = $self->journal;

  if ($self->log_reset) {
    $journal->reset;
  }

  $journal->stream(fun ($info, $data, $lines) {
    my $cont = 1;

    my $from = $info->{from};
    my $tag = $info->{data}{tag} || '--';

    if (my $filter = $self->log_filter_from) {
      $cont = 0 unless $from =~ /$filter/;
    }

    if (my $filter = $self->log_filter_tag) {
      $cont = 0 unless $tag =~ /$filter/;
    }

    if (my $queries = $self->log_filter_queries) {
      for my $query (@$queries) {
        @$lines = grep /$query/, @$lines;
      }
    }

    if ($cont) {
      for my $line (@$lines) {
        $callback->(join ' ', $from, ' ', $tag, ' ', $line);
      }
    }
  });

  return 1;
}

method restart() {
  return $self->stop && $self->start;
}

method start() {
  my $logger = $self->logger;
  my $cartridge = $self->cartridge;
  my $file = $cartridge->pidfile;

  if (-e $file) {
    $logger->fatal("pid file exists: $file");
    return 0;
  }

  open(my $fh, ">", "$file") or do {
    $logger->fatal("pid file error: $!");
    return 0;
  };

  my ($cnt, $err) = do {
    local $@;
    (eval{chmod(0644, $file)}, $@)
  };
  if ($err) {
    $logger->fatal("pid file error: $err");
    return 0;
  }

  my $pid = $self->fork;
  my $name = $cartridge->name;

  print $fh "$pid\n";
  close $fh;

  $logger->info("app created: $name");
  $logger->info("pid file created: $file");

  return 1;
}

method stop() {
  my $logger = $self->logger;
  my $cartridge = $self->cartridge;
  my $file = $cartridge->pidfile;
  my $pid = $cartridge->pid;

  unlink $file;

  if (!$pid) {
    $logger->warn("no pid in file: $file");
  }
  else {
    kill 'TERM', $pid;
  }

  return 1;
}

method update() {
  my $logger = $self->logger;
  my $cartridge = $self->cartridge;
  my $file = $cartridge->pidfile;
  my $pid = $cartridge->pid;

  if (!$pid) {
    $logger->fatal("no pid in file: $file");
    return 0;
  }
  else {
    kill 'USR2', $pid;
  }

  return 1;
}

# ERRORS

fun error_fork(Str $reason) {
  code => 'error_fork',
  message => "Error on fork: $reason",
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

  use Zing::Cartridge;
  use Zing::Daemon;

  my $daemon = Zing::Daemon->new(
    cartridge => Zing::Cartridge->new(
      name => 'example',
      scheme => ['MyApp', [], 1],
    )
  );

  # $daemon->start;

=cut

=head1 DESCRIPTION

This package provides the mechanisms for running a L<Zing> application
as a daemon process.

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Zing::Entity>

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Zing::Types>

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 cartridge

  cartridge(Cartridge)

This attribute is read-only, accepts C<(Cartridge)> values, and is required.

=cut

=head2 journal

  journal(Journal)

This attribute is read-only, accepts C<(Journal)> values, and is optional.

=cut

=head2 kernel

  kernel(Zing)

This attribute is read-only, accepts C<(Zing)> values, and is optional.

=cut

=head2 log_filter_from

  log_filter_from(Str)

This attribute is read-only, accepts C<(Str)> values, and is optional.

=cut

=head2 log_filter_queries

  log_filter_queries(ArrayRef[Str])

This attribute is read-only, accepts C<(ArrayRef[Str])> values, and is optional.

=cut

=head2 log_filter_tag

  log_filter_tag(Str)

This attribute is read-only, accepts C<(Str)> values, and is optional.

=cut

=head2 log_level

  log_level(Str)

This attribute is read-only, accepts C<(Str)> values, and is optional.

=cut

=head2 log_reset

  log_reset(Bool)

This attribute is read-only, accepts C<(Bool)> values, and is optional.

=cut

=head2 log_verbose

  log_verbose(Bool)

This attribute is read-only, accepts C<(Bool)> values, and is optional.

=cut

=head2 logger

  logger(Logger)

This attribute is read-only, accepts C<(Logger)> values, and is optional.

=cut

=head1 METHODS

This package implements the following methods:

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

=head2 restart

  restart() : Bool

The restart method stops and then starts the application and creates a pid file
under the L<Zing::Cartridge/pidfile>.

=over 4

=item restart example #1

  use FlightRecorder;
  use Zing::Cartridge;
  use Zing::Daemon;

  my $daemon = Zing::Daemon->new(
    logger => FlightRecorder->new(auto => undef),
    cartridge => Zing::Cartridge->new(
      name => 'example',
      scheme => ['MyApp', [], 1],
    )
  );

  $daemon->restart;

=back

=cut

=head2 start

  start() : Bool

The start method forks the application and creates a pid file under the
L<Zing::Cartridge/pidfile>.

=over 4

=item start example #1

  use FlightRecorder;
  use Zing::Cartridge;
  use Zing::Daemon;

  my $daemon = Zing::Daemon->new(
    logger => FlightRecorder->new(auto => undef),
    cartridge => Zing::Cartridge->new(
      name => 'example',
      scheme => ['MyApp', [], 1],
    )
  );

  $daemon->start;

=back

=cut

=head2 stop

  stop() : Bool

The stop method stops the application and removes the pid file under the
L<Zing::Cartridge/pidfile>.

=over 4

=item stop example #1

  use FlightRecorder;
  use Zing::Cartridge;
  use Zing::Daemon;

  my $daemon = Zing::Daemon->new(
    logger => FlightRecorder->new(auto => undef),
    cartridge => Zing::Cartridge->new(
      name => 'example',
      scheme => ['MyApp', [], 1],
    )
  );

  $daemon->stop;

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
