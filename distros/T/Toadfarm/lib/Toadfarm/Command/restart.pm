package Toadfarm::Command::restart;
use Mojo::Base 'Toadfarm::Command::stop';

has description => 'Toadfarm: Restart or start the server';

sub run {
  my $self = shift;
  my $exit = $self->_restart;
  return $exit if $ENV{TOADFARM_NO_EXIT};
  exit $exit;
}

sub _restart {
  my ($self, @args) = @_;
  my $exit;
  local $ENV{TOADFARM_NO_EXIT} = 1;
  $exit ||= $self->$_(@args) for qw(_stop _start);
  return $exit;
}

1;

=encoding utf8

=head1 NAME

Toadfarm::Command::restart - Restart a Toadfarm DSL script

=head1 DESCRIPTION

L<Toadfarm::Command::restart> is a command for restarting a L<Toadfarm>
application.

=head1 SYNOPSIS

  $ /path/to/script.pl restart

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
