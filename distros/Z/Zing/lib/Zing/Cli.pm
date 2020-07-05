package Zing::Cli;

use 5.014;

use strict;
use warnings;

use lib '.';

use parent 'Data::Object::Cli';

use Zing;
use Zing::Channel;
use Zing::Daemon;
use Zing::Registry;

use FlightRecorder;
use File::Spec;

our $VERSION = '0.10'; # VERSION

our $name = 'zing <{command}> [<{app}>] [options]';

# METHODS

sub auto {
  {
    clean => '_handle_clean',
    logs => '_handle_logs',
    pid => '_handle_pid',
    restart => '_handle_restart',
    update => '_handle_update',
    start => '_handle_start',
    stop => '_handle_stop',
  }
}

sub subs {
  {
    clean => 'Prune the process registry',
    logs => 'Tap logs and output to STDOUT',
    pid => 'Display an application process ID',
    restart => 'Restart the specified application',
    update => 'Hot-reload application processes',
    start => 'Start the specified application',
    stop => 'Stop the specified application',
  }
}

sub spec {
  {
    appdir => {
      desc => 'Directory of the app file',
      type => 'string',
      flag => 'a',
    },
    process => {
      desc => 'Reduce log output by process name',
      type => 'string',
      flag => 'p',
    },
    level => {
      desc => 'Reduce log output by log-level',
      type => 'string',
      flag => 'l',
    },
    libdir => {
      desc => 'Directory for @INC',
      type => 'string',
      flag => 'I',
      args => '@',
    },
    piddir => {
      desc => 'Directory for the pid file',
      type => 'string',
      flag => 'd',
    },
    tag => {
      desc => 'Reduce log output by process tag',
      type => 'string',
      flag => 't',
    },
    verbose => {
      desc => 'Produce verbose log output',
      type => 'flag',
      flag => 'v',
    },
  }
}

sub _handle_clean {
  my ($self) = @_;

  my $r = Zing::Registry->new;

  for my $id (@{$r->ids}) {
    my $data = $r->store->recv($id) or next;
    my $pid = $data->{process} or next;
    $r->store->drop($id) unless kill 0, $pid;
  }

  return $self;
}

sub _handle_logs {
  my ($self) = @_;

  my $c = Zing::Channel->new(name => '$journal');

  while (1) {
    next unless my $info = $c->recv;

    my $from = $info->{from};
    my $data = $info->{data};
    my $logs = $data->{logs};

    $logs->{level} = $self->opts->level if $self->opts->level;

    my $logger = FlightRecorder->new($logs);
    my $report = $self->opts->verbose ? 'verbose' : 'simple';
    my $lines = $logger->$report->lines;
    my $tag = $data->{tag} || '--';

    if (my $filter = $self->opts->from) {
      next unless $from =~ /$filter/;
    }

    if (my $filter = $self->opts->tag) {
      next unless $tag =~ /$filter/;
    }

    print STDOUT $from, ' ', $tag, ' ', $_, "\n" for @$lines;
  }

  return $self;
}

sub _handle_pid {
  my ($self) = @_;

  my $app = $self->args->app;

  if (!$app) {
    print $self->help, "\n";
    return $self->okay;
  }

  my $piddir = $self->opts->piddir
    || $ENV{ZING_PIDDIR}
    || $ENV{ZING_HOME}
    || File::Spec->curdir;

  my $pidfile = File::Spec->catfile($piddir, "$app.pid");

  if (! -e $pidfile) {
    print "Can't find pid $pidfile\n";
    return $self->fail;
  }

  my $pid = do { local $@; eval { do $pidfile } };

  if (!$pid || ref $pid) {
    print "File didn't return a process ID: $pidfile\n";
    return $self->fail;
  }

  print "Process ID: $pid\n";

  return $self;
}

sub _handle_restart {
  my ($self) = @_;

  $self->_handle_stop;
  $self->_handle_start;

  return $self;
}

sub _handle_start {
  my ($self) = @_;

  my $app = $self->args->app;

  if (!$app) {
    print $self->help, "\n";
    return $self->okay;
  }

  my $appdir = $self->opts->appdir;
  my $piddir = $self->opts->piddir;
  my $libdir = $self->opts->libdir;

  unshift @INC, @$libdir if $libdir;

  $appdir ||= $ENV{ZING_APPDIR} || $ENV{ZING_HOME} || File::Spec->curdir;

  my $appfile = File::Spec->catfile($appdir, $app);

  if (! -e $appfile) {
    print "Can't find app: $appfile\n";
    return $self->fail;
  }

  my $scheme = do { local $@; eval { do $appfile } };

  if (ref $scheme ne 'ARRAY') {
    print "File didn't return an app scheme: $appfile\n";
    return $self->fail;
  }

  my $daemon = Zing::Daemon->new(
    name => $app,
    app => Zing->new(scheme => $scheme),
    ($piddir ? (pid_dir => $piddir) : ()),
  );

  $daemon->start;

  return $self;
}

sub _handle_stop {
  my ($self) = @_;

  my $app = $self->args->app;

  if (!$app) {
    print $self->help, "\n";
    return $self->okay;
  }

  my $piddir = $self->opts->piddir
    || $ENV{ZING_PIDDIR}
    || $ENV{ZING_HOME}
    || File::Spec->curdir;

  my $pidfile = File::Spec->catfile($piddir, "$app.pid");

  if (! -e $pidfile) {
    print "Can't find pid $pidfile\n";
    return $self->fail;
  }

  my $pid = do { local $@; eval { do $pidfile } };

  if (!$pid || ref $pid) {
    print "File didn't return a process ID: $pidfile\n";
    return $self->fail;
  }

  kill 'TERM', $pid;

  unlink $pidfile;

  return $self;
}

sub _handle_update {
  my ($self) = @_;

  my $app = $self->args->app;

  if (!$app) {
    print $self->help, "\n";
    return $self->okay;
  }

  my $piddir = $self->opts->piddir
    || $ENV{ZING_PIDDIR}
    || $ENV{ZING_HOME}
    || File::Spec->curdir;

  my $pidfile = File::Spec->catfile($piddir, "$app.pid");

  if (! -e $pidfile) {
    print "Can't find pid $pidfile\n";
    return $self->fail;
  }

  my $pid = do { local $@; eval { do $pidfile } };

  if (!$pid || ref $pid) {
    print "File didn't return a process ID: $pidfile\n";
    return $self->fail;
  }

  kill 'USR2', $pid;

  return $self;
}

1;


=encoding utf8

=head1 NAME

Zing::Cli - Command-line Interface

=cut

=head1 ABSTRACT

Command-line Process Management

=cut

=head1 SYNOPSIS

  use Zing::Cli;

  my $cli = Zing::Cli->new;

  # $cli->handle('main');

=cut

=head1 DESCRIPTION

This package provides a command-line interface for managing L<Zing>
applications. See the L<zing> documentation for interface arguments and
options.

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Data::Object::Cli>

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Zing::Types>

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 main

  main() : Any

The main method executes the command-line interface and displays help text or
launches applications.

=over 4

=item main example #1

  # given: synopsis

  # e.g.
  # zing start once -I t/lib -a t/app
  # pass

  $cli->handle('main');

=back

=over 4

=item main example #2

  # given: synopsis

  # e.g.
  # zing start unce -I t/lib -a t/app
  # fail (not exist)

  $cli->handle('main');

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
__DATA__

zing - multi-process management system

Usage: {name}

Commands:

{commands}

Options:

{options}
