package Toadfarm::Command::status;
use Mojo::Base 'Toadfarm::Command::start';

use File::Basename 'dirname';
use Mojo::File;
use File::Spec;

has description => 'Toadfarm: Get status from the server';

sub run {
  my ($self, @args) = @_;
  my $moniker  = $self->app->moniker;
  my $pid_file = $self->_pid_file;

  # 0 program is running or service is OK
  # 1 program is dead and /var/run pid file exists
  # 3 program is not running

  unless (-e $pid_file) {
    return $self->_end(3, 'no pid file');
  }

  my ($pid) = Mojo::File->new($pid_file)->slurp =~ /(\d+)/;
  if ($pid and !kill 0, $pid) {
    $pid ||= 0;
    return $self->_end(1, "but $pid_file exists");
  }

  return $self->_end(0);
}

sub _end {
  my ($self, $exit, $message) = @_;
  my $format = $exit ? 'Process %s is not running (%s)' : 'Process %s is running';
  $self->_printf(" * $format\n", $self->app->moniker, $message);
  return $exit if $ENV{TOADFARM_NO_EXIT};
  exit $exit;
}

1;

=encoding utf8

=head1 NAME

Toadfarm::Command::status - Get status from a Toadfarm DSL script

=head1 DESCRIPTION

L<Toadfarm::Command::status> is a command for retrieving status from  a
L<Toadfarm> application.

=head1 SYNOPSIS

  $ /path/to/script.pl status

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
