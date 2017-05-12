package Unicorn::Manager::Server;

use 5.010;
use feature 'say';
use strict;
use warnings;
use autodie;
use Moo;
use JSON;
use Try::Tiny;
use Unicorn::Manager::Server::PreFork;

has listen => (
    is  => 'rw',
    isa => Unicorn::Manager::Types::local_address,
);
has port   => ( is => 'rw' );
has user   => ( is => 'rw' );
has group  => ( is => 'rw' );
has server => ( is => 'rw' );

sub BUILD {
    my $self = shift;

    $self->user('nobody')       unless $self->user;
    $self->group( $self->user ) unless $self->group;
    $self->port(4242)           unless $self->port;
    $self->listen('localhost')  unless $self->listen;

    $self->server(
        Unicorn::Manager::Server::PreFork->new(
            user   => $self->user,
            group  => $self->group,
            port   => $self->port,
            listen => $self->listen,
        )
    );

}

sub run {
    my $self = shift;
    $self->server->start();
}

1;

__END__

=head1 NAME

Unicorn::Manager::Server - A Perl interface to the Unicorn webserver

=head1 WARNING!

This is an unstable development release not ready for production!

=head1 VERSION

Version 0.006009

=head1 SYNOPSIS

The Unicorn::Manager::Server module provides a json interface to query information about running unicorn processes and users.

Also some assumption are made about your environment:
    you use Linux (the module relies on /proc)
    you use the bash shell
    your unicorn config is located in your apps root directory
    every user is running one single application

I will add and improve what is needed though. Requests and patches are
welcome.

=head1 ATTRIBUTES/CONSTRUCTION

=head2 listen

Address to listen on. Defaults to localhost.

=head2 port

Port to bind to.

=head2 user

Username to use for Unicorn::Manager::CLI instances.

=head2 group

Not in use yet.

=head2 server

A Unicorn::Manager::Server::* instance. Will be created automatically unless provided in construction.
Currently only Unicorn::Manager::Server::Prefork is implemented.

=head1 METHODS

=head2 run

=head1 AUTHOR

Mugen Kenichi, C<< <mugen.kenichi at uninets.eu> >>

=head1 BUGS

Report bugs at:

=over 2

=item * Unicorn::Manager::CLI issue tracker

L<https://github.com/mugenken/Unicorn/issues>

=item * support at uninets.eu

C<< <mugen.kenichi at uninets.eu> >>

=back

=head1 SUPPORT

=over 2

=item * Technical support

C<< <mugen.kenichi at uninets.eu> >>

=back

=cut
