package Toadfarm::Command::start;
use Mojo::Base 'Toadfarm::Command::tail';

use File::Basename 'dirname';
use File::Spec;
use Time::HiRes 'usleep';

$ENV{TOADFARM_VERBOSE} //= $ENV{HARNESS_IS_VERBOSE} || -t STDOUT;

has description => 'Toadfarm: Start the server if not already running';

sub run { shift->_start(@_) }

sub _hypnotoad {
  my $self = shift;

  for my $p (File::Spec->path, dirname($^X)) {
    my $exe = File::Spec->catfile($p, 'hypnotoad');
    return $exe if -r $exe;
  }

  die "Cannot find 'hypnotoad' in \$PATH.";
}

sub _is_running {
  my $self = shift;
  my $pid  = $self->_pid;
  return $pid && kill 0, $pid;
}

sub _end {
  my ($self, $exit, $message) = @_;

  if ($message and $ENV{TOADFARM_VERBOSE}) {
    $self->_printf("   ...%s (%s)\n", $exit ? "fail!" : "done.", $message);
  }
  else {
    $self->_printf("   ...%s\n", $exit ? "fail!" : "done.");
  }

  return $exit if $ENV{TOADFARM_NO_EXIT};
  exit $exit;
}

sub _log_daemon_msg {
  my ($self, $message) = @_;
  $self->_printf(" * $message\n", $self->app->moniker);
}

sub _pid {
  my $self = shift;
  my $file = $self->_pid_file;
  return 0 unless $file and -e $file;
  open my $PID, '<', $file or die "Unable to read pid_file $file: $!\n";
  my $pid = join '', <$PID>;
  return $pid =~ /(\d+)/ ? $1 : 0;
}

sub _pid_file {
  my $self    = shift;
  my $moniker = $self->app->moniker;
  return $self->app->config->{hypnotoad}{pid_file}
    || die "$moniker has invalid config: /hypnotoad/pid_file is not set.\n";
}

sub _printf { shift; printf shift, @_; }

sub _start {
  my ($self, @args) = @_;
  my $pid = $self->_pid;
  my $tail = grep {/^--tail/} @args;

  $self->_log_daemon_msg('Starting the process %s');

  # running
  if ($self->_is_running) {
    return $self->_tail(grep { !/^--tail/ } @args) if $tail;
    return $self->_end(0, "already running with pid=$pid");
  }

  # start
  system $self->_hypnotoad, $0;
  my $exit = $? >> 8;
  return $self->_end($exit, "hypnotoad $0 = $exit") if $exit;

  # wait until started
  $self->_wait_for(5 => sub { shift->_is_running });

  # check if started
  return $self->_end(3, 'daemon is not running') unless $self->_is_running;
  return $self->_tail(grep { !/^--tail/ } @args) if $tail;
  return $self->_end(0);

}

sub _wait_for {
  my ($self, $cb) = (shift, pop);
  my $timeout = shift || ($self->app->config->{hypnotoad}{graceful_timeout} || 20) + 5;

  while ($timeout--) {
    last if $self->$cb;
  }
  continue {
    usleep(300e3);
  }
}

1;

=encoding utf8

=head1 NAME

Toadfarm::Command::start - Start a Toadfarm DSL script

=head1 DESCRIPTION

L<Toadfarm::Command::start> is a command for starting a L<Toadfarm> application.

=head1 SYNOPSIS

  $ /path/to/script.pl start
  $ /path/to/script.pl start --tail <args>

=head1 ATTRIBUTES

=head2 description

Short description of command, used for the command list.

=head1 METHODS

=head2 run

Run command.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014, Jan Henning Thorsen

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 AUTHOR

Jan Henning Thorsen - C<jhthorsen@cpan.org>

=cut
