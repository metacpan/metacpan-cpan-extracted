package Unicorn::Manager::Server::PreFork;

use Moo;
use feature 'say';
use strict;
use warnings;
use autodie;
use 5.010;

use Unicorn::Manager::CLI;
use Unicorn::Manager::Types;
use JSON;
use Try::Tiny;

extends 'Net::Server::PreFork';

has listen => (
    is  => 'rw',
    isa => Unicorn::Manager::Types::local_address,
);
has port  => ( is => 'rw' );
has user  => ( is => 'rw' );
has group => ( is => 'rw' );
has cli   => ( is => 'rw' );
has json  => ( is => 'rw' );

sub BUILD {
    my $self = shift;

    $self->user('nobody')       unless $self->user;
    $self->group( $self->user ) unless $self->group;
    $self->port(4242)           unless $self->port;
    $self->listen('localhost')  unless $self->listen;

    $self->json( JSON->new->utf8(1) );
    $self->cli( Unicorn::Manager::CLI->new( username => $self->user ) ) unless $self->cli;

}

sub process_request {
    my $self        = shift;
    my $timeout_msg = '{"status":0,"data":{},"message":"timeout"}';

    eval {
        local $SIG{ALRM} = sub { die $timeout_msg };

        my $timeout = 10;

        my $previous_alarm = alarm $timeout;

        while (<>) {
            s/\r?\n$//;
            my $json_string = $_;
            my $response    = '{"status":0,"data":{},"message":"invalid request"}';

            try {
                my $data = $self->json->decode($json_string);
                if ( exists $data->{query} ) {
                    $response = $self->cli->query( $data->{query}, @{ $data->{args} } );
                }
                print $response;
            }
            catch {
                print $response;
            };

            return;
        }

        alarm $previous_alarm;

    };

    if ( $@ =~ $timeout_msg ) {
        print $timeout_msg;
        return;
    }

}

sub start {
    my $self = shift;
    $self->run( port => $self->port );
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

=head2 cli

A Unicorn::Manager::CLI instance. Will be created automatically unless provided in construction.

=head2 json

JSON instance. Automatically created with JSON->new->utf8(1).

=head1 METHODS

=head2 start

Start the server.

=head2 process_request


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
