package Toadfarm::Command::stop;
use Mojo::Base 'Toadfarm::Command::start';
use Time::HiRes 'usleep';

$ENV{TOADFARM_STOP_SIGNAL} //= 'QUIT';

has description => 'Toadfarm: Stop the server';

sub run { shift->_stop(@_) }

sub _stop {
  my $self = shift;
  my $pid  = $self->_pid;

  # stop
  $self->_log_daemon_msg('Stopping the process %s');
  return $self->_end(0) unless $self->_is_running;
  kill $ENV{TOADFARM_STOP_SIGNAL}, $pid or return $self->_end($!, 'kill failed') if $pid;

  # wait until stopped
  $self->_wait_for(sub { !shift->_is_running });

  # check if stopped
  $pid = $self->_pid || 0;
  return $self->_end($self->_is_running ? 1 : 0, $pid ? "running with pid=$pid" : "");
}

1;

=encoding utf8

=head1 NAME

Toadfarm::Command::stop - Stop a Toadfarm DSL script

=head1 DESCRIPTION

L<Toadfarm::Command::stop> is a command for stopping a L<Toadfarm> application.

=head1 SYNOPSIS

  $ /path/to/script.pl stop

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
