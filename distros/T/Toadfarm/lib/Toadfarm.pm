package Toadfarm;
use Mojo::Base 'Mojolicious';

use Cwd 'abs_path';
use Data::Dumper ();
use File::Basename qw(basename dirname);
use File::Spec;
use File::Which;
use Mojo::File;
use Mojo::Util qw(class_to_path monkey_patch);

use constant DEBUG => $ENV{TOADFARM_DEBUG} ? 1 : 0;

our $VERSION = '0.84';

BEGIN {
  $ENV{TOADFARM_ACTION} //= (@ARGV and $ARGV[0] =~ /^(reload|start|stop)$/) ? $1 : 'load';
  $ENV{MOJO_CONFIG} = $ENV{TOADFARM_CONFIG} if $ENV{TOADFARM_CONFIG};
}

sub import {
  return unless grep {/^(-dsl|-init|-test)/} @_;

  my $class  = shift;
  my $caller = caller;
  my $app    = Toadfarm->new;
  my $tf     = $app->config->{tf} ||= {};    # internal

  $_->import for qw(strict warnings utf8);
  feature->import(':5.10');
  unshift @{$app->commands->namespaces}, 'Toadfarm::Command';

  monkey_patch $caller, (
    app         => sub {$app},
    change_root => \&_change_root,
    logging     => sub { $tf->{logging}++; $app->_setup_log(@_) },
    mount       => sub { push @{$app->config->{apps}}, @_ == 2 ? @_ : ($_[0], {}); $app },
    plugin      => sub { push @{$app->config->{tf_plugins}}, @_ == 2 ? @_ : ($_[0], {}); $app },
    run_as      => \&_run_as,
    secrets     => sub { $tf->{secrets}++; $app->secrets([@_]) },
    start       => sub {
      if (@_) {
        my $listen = ref $_[0] eq 'ARRAY' ? shift : undef;
        $app->config->{hypnotoad}         = @_ > 1 ? {@_} : {%{$_[0]}} if @_;
        $app->config->{hypnotoad}{listen} = $listen if $listen;
      }

      $app->moniker($class->_moniker) if $app->moniker eq 'toadfarm';
      $app->config->{hypnotoad}{pid_file} ||= $class->_pid_file($app);
      $app = $class->_setup_app($app) if $ENV{TOADFARM_ACTION};
      Mojo::UserAgent::Server->app($app);
      warn '$config=' . Mojo::Util::dumper($app->config) if DEBUG;
      $class->_die_on_insecure($app) unless $ENV{TOADFARM_INSECURE};
      $app->start;
    },
  );
}

sub startup {
  my $self   = shift;
  my $config = $ENV{MOJO_CONFIG} ? $self->plugin('Config') : {};

  # remember the config when hot reloading the app
  $ENV{TOADFARM_CONFIG} = delete $ENV{MOJO_CONFIG};

  $self->{mounted} = 0;
  $self->_setup_log($config->{log})                if $config->{log}{file};
  $self->_paths($config->{paths})                  if $config->{paths};
  $self->secrets([$config->{secret}])              if $config->{secret};
  $self->secrets($config->{secrets})               if $config->{secrets};
  $self->_mount_apps(@{$config->{apps}})           if $config->{apps};
  $self->_load_plugins(@{$config->{tf_plugins}})   if $config->{tf_plugins};
  $self->_mount_root_app(delete $self->{root_app}) if $self->{root_app};
}

sub _change_root {
  my @cmd  = @_;
  my $exit = -2;

  return 1 if $<;    # not root

  unshift @cmd, $ENV{TOADFARM_CHROOT_BIN} || 'chroot';
  push @cmd, $^X;
  push @cmd, -I => $INC[0] if $ENV{TOADFARM_ACTION} eq 'test';
  push @cmd, File::Spec->rel2abs($0), @ARGV;

  warn "[Toadfarm] system @cmd\n" if DEBUG;
  system @cmd;
  die "Could not run '@cmd' exit=$exit\n" if $exit = $? >> 8;
  exit $?;
}

sub _die_on_insecure {
  my ($class, $app) = @_;
  my $config  = $app->config;
  my $plugins = $config->{tf_plugins} || [];

  die "Cannot change user without TOADFARM_INSECURE=1"  if $config->{hypnotoad}{user};
  die "Cannot change group without TOADFARM_INSECURE=1" if $config->{hypnotoad}{group};
  die "Cannot run as 'root' without TOADFARM_INSECURE=1"
    if +($> == 0 or $< == 0)
    and !grep {/\bSetUserGroup$/} @$plugins;
}

sub _exit { say shift and exit 0 }

sub _load_plugins {
  my $self = shift;

  unshift @{$self->plugins->namespaces}, 'Toadfarm::Plugin';

  while (@_) {
    my ($plugin, $config) = (shift @_, shift @_);
    $self->log->info("Loading plugin $plugin");
    $self->plugin($plugin, $config);
  }
}

sub _moniker {
  my $moniker = basename $0;
  $moniker =~ s!\W!_!g;
  $moniker;
}

sub _mount_apps {
  my $self   = shift;
  my $routes = $self->routes;
  my $config = $self->config;

  while (@_) {
    my ($app, $rules) = (shift @_, shift @_);
    my $server      = Mojo::Server->new;
    my $mount_point = delete $rules->{mount_point};
    my ($request_base, $tmp, @over);

    local $ENV{MOJO_CONFIG} = $ENV{MOJO_CONFIG};

    if (ref $rules->{config} eq 'HASH') {
      require File::Temp;
      my %config = (%{$self->config}, %{$rules->{config}});
      $tmp = File::Temp->new;
      Mojo::File->new($tmp->filename)->spurt(
        do {
          local $Data::Dumper::Terse    = 1;
          local $Data::Dumper::Deepcopy = 1;
          Data::Dumper::Dumper(\%config);
        }
      );
      $ENV{MOJO_CONFIG} = $tmp->filename;
    }

    unless (ref $app and UNIVERSAL::isa($app, 'Mojolicious')) {
      my ($class, $path, @error) = ($app, $app);
      $path = File::Which::which($path) || class_to_path($path) unless -r $path;
      $app  = eval { $server->build_app($class) } or push @error, $@ if $class =~ /^[\w:]+$/;
      $app  = eval { $server->load_app($path) }   or push @error, $@ unless ref $app;
      die join "\n", @error unless $app;
    }

    $app->log($self->log)         if $config->{log}{combined};
    $app->secrets($self->secrets) if $config->{tf}{secrets};

    if (ref $rules->{config} eq 'HASH') {
      my $local = delete $rules->{config};
      $app->config->{$_} = $local->{$_} for keys %$local;
    }

    $app->config->{$_} ||= $config->{$_} for keys %$config;

    for my $k (qw(local_port remote_address remote_port)) {
      push @over, $self->_skip_if(tx => $k, delete $rules->{$k});
    }

    for my $name (sort keys %$rules) {
      $request_base = $rules->{$name} if $name eq 'X-Request-Base';
      push @over, $self->_skip_if(header => $name, $rules->{$name});
    }

    if (@over) {
      $self->log->info("Mounting @{[$app->moniker]} with conditions");
      unshift @over, "sub { my \$h = \$_[1]->req->headers;\nlocal \$1;";
      push @over, "\$_[1]->req->url->base(Mojo::URL->new(\$1 || '$request_base'));" if $request_base;
      push @over, "return 1; }";
      $routes->add_condition("toadfarm_condition_$self->{mounted}", => eval "@over" || die "@over: $@");
      $routes->any($mount_point || '/')->requires("toadfarm_condition_$self->{mounted}")->partial(1)->to(app => $app);
    }
    elsif ($mount_point) {
      $routes->any($mount_point)->partial(1)->to(app => $app);
    }
    else {
      $self->{root_app} = $app;
    }

    $self->{mounted}++;
  }

  $self;
}

sub _mount_root_app {
  my ($self, $app) = @_;
  $self->log->info("Mounting @{[$app->moniker]} without conditions.");
  $self->routes->any('/')->partial(1)->to(app => $app);
}

sub _paths {
  my ($self, $config) = @_;

  for my $type (qw(renderer static)) {
    my $paths = $config->{$type} or next;
    $self->$type->paths($paths);
  }
}

sub _pid_file {
  my ($class, $app) = @_;
  my $name = basename $0;
  my $dir  = dirname abs_path $0;

  return File::Spec->catfile($dir,               "$name.pid") if -w $dir;
  return File::Spec->catfile(File::Spec->tmpdir, "toadfarm-$name.pid");
}

sub _run_as {
  my $user = shift || die "Usage: run_as('username')";
  my ($exit, $uid, @sudo);

  $uid = $user =~ m!^\d+$! ? $user : scalar getpwnam $user;
  die "Could not find uid for user $user\n" unless $uid;
  return 1 if $uid == $>;

  for my $p (File::Spec->path) {
    $sudo[0] = File::Spec->catfile($p, 'sudo');
    next unless -x $sudo[0];
    push @sudo, qw(-i -n -u), "#$uid";
    last;
  }

  die "Cannot change to uid=$uid: 'sudo' was not found.\n" unless @sudo > 1;
  push @sudo, $^X;
  push @sudo, -I => $INC[0] if $ENV{TOADFARM_ACTION} eq 'test';
  push @sudo, File::Spec->rel2abs($0), @ARGV;
  warn "[Toadfarm] system @sudo\n" if DEBUG;
  system @sudo;
  die "Could not run '@sudo' exit=$exit\n" if $exit = $? >> 8;
  exit $?;
}

sub _setup_app {
  my ($class, $app) = @_;
  my $config = $app->config;

  $app->secrets([Mojo::Util::md5_sum($$ . $0 . time . rand)]) unless $config->{tf}{secrets};
  $app->_mount_apps(@{$config->{apps}})         if $config->{apps};
  $app->_load_plugins(@{$config->{tf_plugins}}) if $config->{tf_plugins};

  if (my $root_app = delete $app->{root_app}) {
    if (@{$config->{apps} || []} == 2) {
      my $plugins = $config->{tf_plugins} || [];
      $root_app->config(hypnotoad => $config->{hypnotoad}) if $config->{hypnotoad};
      $root_app->log($app->log)                            if $config->{tf}{logging};
      $root_app->plugin(shift(@$plugins), shift(@$plugins)) for @$plugins;
      $root_app->secrets($app->secrets);
      push @{$root_app->commands->namespaces}, 'Toadfarm::Command';
      return $root_app;
    }
    else {
      $app->_mount_root_app($root_app);
    }
  }

  return $app;
}

sub _setup_log {
  my ($self, $config) = @_;
  my $log = Mojo::Log->new;

  $self->config(log => $config);
  $log->path($config->{path}) if $config->{path} ||= delete $config->{file};
  $log->level($config->{level} || 'info');
  $self->log($log);
}

sub _skip_if {
  my ($self, $type, $k, $value) = @_;
  my $format = $type eq 'tx' ? '$_[1]->tx->%s' : $type eq 'header' ? q[$h->header('%s')] : q[INVALID(%s)];

  if (!defined $value) {
    return;
  }
  elsif (ref $value eq 'Regexp') {
    $value =~ s,(?<!\\)/,\\/,g;
    return sprintf "return 0 unless +($format || '') =~ /(%s)/;", $k, $value;
  }
  else {
    return sprintf "return 0 unless +($format || '') eq '%s';", $k, $value;
  }
}

1;

=encoding utf8

=head1 NAME

Toadfarm - One Mojolicious app to rule them all

=head1 VERSION

0.84

=head1 DESCRIPTION

Toadfarm is a module for configuring and starting your L<Mojolicious>
applications. You can either combine multiple applications in one script,
or just use it as a init script.

Core features:

=over 4

=item *

Wrapper around L<hypnotoad|Mojo::Server::Hypnotoad> that makes your
application L<Sys-V|https://www.debian-administration.org/article/28/Making_scripts_run_at_boot_time_with_Debian>
compatible.

=item *

Advanced routing and virtual host configuration. Also support routing
from behind another web server, such as L<nginx|http://nginx.com/>.
This feature is very much like L<Mojolicious::Plugin::Mount> on steroids.

=item *

Hijacking log messages to a common log file. There's also plugin,
L<Toadfarm::Plugin::AccessLog>, that allows you to log the requests sent
to your server.

=back

=head1 SYNOPSIS

=head2 Script

Here is an example script that sets up logging and mounts some applications
under different domains, as well as loading in some custom plugins.

See L<Toadfarm::Manual::DSL> for more information about the different functions.

  #!/usr/bin/perl
  use Toadfarm -init;

  logging {
    combined => 1,
    file     => "/var/log/toadfarm/app.log",
    level    => "info",
  };

  mount "MyApp"  => {
    Host   => "myapp.example.com",
    config => {
      config_parameter_for_myapp => "foo"
    },
  };

  mount "/path/to/app" => {
    Host        => "example.com",
    mount_point => "/other",
  };

  mount "Catch::All::App";

  plugin "Toadfarm::Plugin::AccessLog";

  start; # needs to be at the last line

=head2 Usage

You don't have to put L</Script> in init.d, but it will work with standard
start/stop actions.

  $ /etc/init.d/your-script reload
  $ /etc/init.d/your-script start
  $ /etc/init.d/your-script stop

See also L<Toadfarm::Manual::RunningToadfarm/Init script> for more details.

You can also start the application with normal L<Mojolicious> commands:

  $ morbo /etc/init.d/your-script
  $ /etc/init.d/your-script daemon

=head1 DOCUMENTATION INDEX

=over 4

=item * L<Toadfarm::Manual::Intro> - Introduction.

=item * L<Toadfarm::Manual::DSL> - Domain specific language for Toadfarm.

=item * L<Toadfarm::Manual::Config> - Config file format.

=item * L<Toadfarm::Manual::RunningToadfarm> - Command line options.

=item * L<Toadfarm::Manual::BehindReverseProxy> - Toadfarm behind nginx.

=item * L<Toadfarm::Manual::VirtualHost> - Virtual host setup.

=back

=head1 PLUGINS

=over 4

=item * L<Toadfarm::Plugin::AccessLog>

Log each request that hit your application.

=item * L<Mojolicious::Plugin::SizeLimit>

Kill Hypnotoad workers if they grow too large.

=item * L<Mojolicious::Plugin::SetUserGroup>

Start as root, run workers as less user. See also
L<Toadfarm::Manual::RunningToadfarm/Listen to standard HTTP ports>.

=back

=head1 PREVIOUS VERSIONS

L<Toadfarm> prior to version 0.49 used to be a configuration file loaded in
by the C<toadfarm> script. This resulted in all the executables to be named
C<toadfarm> instead of something descriptive. It also felt a bit awkward to
take over C<MOJO_CONFIG> and use all the crazy hacks to start C<hypnotoad>.

It also didn't work well as an init script, so there still had to be a
seperate solution for that.

The new L<Toadfarm> DSL aim to solve all of these issues. This means that
if you decide to still use any C<MOJO_CONFIG>, it should be for the
applications loaded from inside C<Toadfarm> and not the startup script.

Note that the old solution still works, but a warning tells you to change
to the new L<DSL|Toadfarm::Manual::DSL> based API.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014, Jan Henning Thorsen

This program is free software, you can redistribute it and/or modify it
under the terms of the Artistic License version 2.0.

=head1 AUTHOR

Jan Henning Thorsen - C<jhthorsen@cpan.org>

=cut
