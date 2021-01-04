package Zing::Cli;

use 5.014;

use strict;
use warnings;

use feature 'say';

use lib '.';

use registry 'Zing::Types';
use routines;

use Data::Object::Class;
use Data::Object::ClassHas;

extends 'Data::Object::Cli';

our $VERSION = '0.25'; # VERSION

# ATTRIBUTES

has app => (
  is => 'ro',
  isa => 'App',
  new => 1,
);

fun new_app($self) {
  require Zing::App;
  require Zing::Env;

  Zing::App->new(
    env => Zing::Env->new(
      $self->opt_appdir ? (
        appdir => $self->opt_appdir
      ) : (),
      $self->opt_handle ? (
        handle => $self->opt_handle
      ) : (),
      $self->opt_level ? (
        level => $self->opt_level
      ) : (),
      $self->opt_piddir ? (
        piddir => $self->opt_piddir
      ) : (),
      $self->opt_target ? (
        target => $self->opt_target
      ) : (),
    )
  )
}

has arg_app => (
  is => 'ro',
  isa => 'Maybe[Str]',
  new => 1,
);

fun new_arg_app($self) {
  $self->args->app
}

has cartridge => (
  is => 'ro',
  isa => 'Cartridge',
  new => 1,
);

fun new_cartridge($self) {
  $self->app->cartridge(
    name => $self->arg_app,
    $self->opt_appdir ? (
      appdir => $self->opt_appdir
    ) : (),
    $self->opt_libdir ? (
      libdir => $self->opt_libdir
    ) : (),
    $self->opt_piddir ? (
      piddir => $self->opt_piddir
    ) : (),
  )
}

has daemon => (
  is => 'ro',
  isa => 'Daemon',
  new => 1,
);

fun new_daemon($self) {
  $self->app->daemon(
    cartridge => $self->cartridge,
    $self->opt_backlog ? (
      log_reset => $self->opt_backlog
    ) : (),
    $self->opt_level ? (
      log_level => $self->opt_level
    ) : (),
    $self->opt_process ? (
      log_filter_from => $self->opt_process
    ) : (),
    $self->opt_search ? (
      log_filter_queries => $self->$self->opt_search
    ) : (),
    $self->opt_tag ? (
      log_filter_tag => $self->opt_tag
    ) : (),
    $self->opt_verbose ? (
      log_verbose => $self->opt_verbose
    ) : (),
  )
}

has opt_appdir => (
  is => 'ro',
  isa => 'Maybe[Str]',
  new => 1,
);

fun new_opt_appdir($self) {
  $self->opts->appdir
}

has opt_backlog => (
  is => 'ro',
  isa => 'Maybe[Bool]',
  new => 1,
);

fun new_opt_backlog($self) {
  $self->opts->backlog
}

has opt_target => (
  is => 'ro',
  isa => 'Maybe[Str]',
  new => 1,
);

fun new_opt_target($self) {
  $self->opts->target
}

has opt_handle => (
  is => 'ro',
  isa => 'Maybe[Str]',
  new => 1,
);

fun new_opt_handle($self) {
  $self->opts->handle
}

has opt_level => (
  is => 'ro',
  isa => 'Maybe[Str]',
  new => 1,
);

fun new_opt_level($self) {
  $self->opts->level
}

has opt_libdir => (
  is => 'ro',
  isa => 'Maybe[ArrayRef[Str]]',
  new => 1,
);

fun new_opt_libdir($self) {
  $self->opts->libdir
}

has opt_package => (
  is => 'ro',
  isa => 'Maybe[Str]',
  new => 1,
);

fun new_opt_package($self) {
  $self->opts->package
}

has opt_piddir => (
  is => 'ro',
  isa => 'Maybe[Str]',
  new => 1,
);

fun new_opt_piddir($self) {
  $self->opts->piddir
}

has opt_process => (
  is => 'ro',
  isa => 'Maybe[Str]',
  new => 1,
);

fun new_opt_process($self) {
  $self->opts->process
}

has opt_search => (
  is => 'ro',
  isa => 'Maybe[ArrayRef[Str]]',
  new => 1,
);

fun new_opt_search($self) {
  $self->opts->search
}

has opt_tag => (
  is => 'ro',
  isa => 'Maybe[Str]',
  new => 1,
);

fun new_opt_tag($self) {
  $self->opts->tag
}

has opt_verbose => (
  is => 'ro',
  isa => 'Maybe[Bool]',
  new => 1,
);

fun new_opt_verbose($self) {
  $self->opts->verbose
}

# USAGE

our $name = 'zing <{command}> [<{app}>] [options]';

# CONFIGURATION

fun auto() {
  {
    install => 'handle_install',
    logs => 'handle_logs',
    monitor => 'handle_monitor',
    pid => 'handle_pid',
    restart => 'handle_restart',
    start => 'handle_start',
    stop => 'handle_stop',
    update => 'handle_update',
  }
}

fun subs() {
  {
    install => 'Create an application cartridge',
    logs => 'Tap logs and output to STDOUT',
    monitor => 'Monitor the specified application (start if not started)',
    pid => 'Display an application process ID',
    restart => 'Restart the specified application',
    start => 'Start the specified application',
    stop => 'Stop the specified application',
    update => 'Hot-reload application processes',
  }
}

fun spec() {
  {
    appdir => {
      desc => 'Directory of the app file',
      type => 'string',
      flag => 'a',
    },
    backlog => {
      desc => 'Produce log output using the backlog',
      type => 'flag',
      flag => 'b',
    },
    handle => {
      desc => 'Provide a handle (namespace)',
      type => 'string',
      flag => 'h',
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
      flag => 'i',
      args => '@',
    },
    package => {
      desc => 'Provide a process package name',
      type => 'string',
      flag => 'n',
    },
    piddir => {
      desc => 'Directory for the pid file',
      type => 'string',
      flag => 'd',
    },
    search => {
      desc => 'Reduce log output by search string',
      type => 'string',
      flag => 's',
      args => '@',
    },
    target => {
      desc => 'Provide a target (package)',
      type => 'string',
      flag => 'r',
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

# METHODS

method handle_install() {
  if (!$self->arg_app) {
    $self->output('error: app required');
    exit(1);
  }
  if (!$self->opt_package) {
    $self->output('error: package required');
    exit(1);
  }
  else {
    my $space = Data::Object::Space->new($self->opt_package);
    my %seen = map {$_, 1} @INC;
    for my $dir (@{$self->opt_libdir}) {
      push @INC, $dir if !$seen{$dir}++;
    }
    if (!$space->load->can('install')) {
      $self->output('error: uninstallable');
      exit(1);
    }
    else {
      $self->output('installing ...');
      $self->cartridge->install($space->build->install);
      exit(0);
    }
  }
}

method handle_logs() {
  if (!$self->arg_app) {
    $self->output('error: app required');
    exit(1);
  }
  else {
    $self->daemon->logs(fun($line) {
      $self->output($line);
    });
    exit(0);
  }
}

method handle_monitor() {
  if (!$self->arg_app) {
    $self->output('error: app required');
    exit(1);
  }
  else {
    $self->output('monitoring ...');
  }
  if (!-e $self->cartridge->pidfile) {
    $self->daemon->start;
  }
  $self->handle_logs;
  exit(0);
}

method handle_pid() {
  if (!$self->arg_app) {
    $self->output('error: app required');
    exit(1);
  }
  else {
    if (my $pid = $self->cartridge->pid) {
      $self->output($pid);
      exit(0);
    }
    else {
      $self->output('error: no pid');
      exit(1);
    }
  }
}

method handle_restart() {
  if (!$self->arg_app) {
    $self->output('error: app required');
    exit(1);
  }
  elsif (!-f $self->cartridge->appfile) {
    $self->output('error: app not found');
    exit(1);
  }
  else {
    $self->output('restarting ...');
  }
  exit(!$self->daemon->restart);
}

method handle_start() {
  if (!$self->arg_app) {
    $self->output('error: app required');
    exit(1);
  }
  elsif (!-f $self->cartridge->appfile) {
    $self->output('error: app not found');
    exit(1);
  }
  else {
    $self->output('starting ...');
  }
  exit(!$self->daemon->start);
}

method handle_stop() {
  if (!$self->arg_app) {
    $self->output('error: app required');
    exit(1);
  }
  elsif (!-f $self->cartridge->appfile) {
    $self->output('error: app not found');
    exit(1);
  }
  else {
    $self->output('stopping ...');
  }
  exit(!$self->daemon->stop);
}

method handle_update() {
  if (!$self->arg_app) {
    $self->output('error: app required');
    exit(1);
  }
  elsif (!-f $self->cartridge->appfile) {
    $self->output('error: app not found');
    exit(1);
  }
  else {
    $self->output('updating ...');
  }
  exit(!$self->daemon->update);
}

method output(Str @args) {
  say $_ for @args; return $self;
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
