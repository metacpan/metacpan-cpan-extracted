package Toadfarm::Command::reload;
use Mojo::Base 'Toadfarm::Command::start';

has description => 'Toadfarm: Hot deploy or start the server';

sub run {
  my $self = shift;

  if (grep {/^--tail/} @_) {
    exec $self->_hypnotoad, $0 unless fork;    # start or hot reload
    return $self->_tail(grep { !/^--tail/ } @_);
  }

  # reload
  $self->_log_daemon_msg('Reloading the process %s');
  system $self->_hypnotoad, $0;                # start or hot reload
  $self->_end($? >> 8);
}

1;

=encoding utf8

=head1 NAME

Toadfarm::Command::reload - Reload a Toadfarm DSL script

=head1 DESCRIPTION

L<Toadfarm::Command::reload> is a command for reloading a L<Toadfarm>
application.

=head1 SYNOPSIS

  $ /path/to/script.pl reload
  $ /path/to/script.pl reload --tail <args>

C<--tail> will pass the call L<Toadfarm::Command::tail> after issuing
start/reload on C<script.pl>.

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
