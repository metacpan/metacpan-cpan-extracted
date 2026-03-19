package Testcontainers::Wait::HostPort;
# ABSTRACT: Wait strategy for listening ports

use strict;
use warnings;
use Moo;
use Carp qw( croak );
use IO::Socket::INET;
use Log::Any qw( $log );

our $VERSION = '0.001';

with 'Testcontainers::Wait::Base';

=head1 SYNOPSIS

    use Testcontainers::Wait;

    # Wait for a specific port
    my $wait = Testcontainers::Wait::for_listening_port('80/tcp');

    # Wait for the lowest exposed port
    my $wait = Testcontainers::Wait::for_exposed_port();

=head1 DESCRIPTION

Waits for a TCP port to be listening on the container. This is the most common
wait strategy, equivalent to Go's C<wait.ForListeningPort()>.

=cut

has port => (
    is      => 'ro',
    default => undef,
);

=attr port

The container port to check (e.g., C<80/tcp>). If not set and
C<use_lowest_port> is true, uses the lowest exposed port.

=cut

has use_lowest_port => (
    is      => 'ro',
    default => 0,
);

=attr use_lowest_port

If true, wait for the lowest exposed port instead of a specific one.

=cut

sub check {
    my ($self, $container) = @_;

    my $port = $self->_resolve_port($container);
    my $host = $container->host;
    my $mapped_port = eval { $container->mapped_port($port) };

    unless ($mapped_port) {
        $log->tracef("Port %s not yet mapped", $port);
        return 0;
    }

    $log->tracef("Checking %s:%s (container port %s)", $host, $mapped_port, $port);

    my $sock = IO::Socket::INET->new(
        PeerAddr => $host,
        PeerPort => $mapped_port,
        Proto    => 'tcp',
        Timeout  => 1,
    );

    if ($sock) {
        close($sock);
        $log->debugf("Port %s is listening on %s:%s", $port, $host, $mapped_port);
        return 1;
    }

    return 0;
}

=method check($container)

Check if the target port is listening. Returns true/false.

=cut

sub _resolve_port {
    my ($self, $container) = @_;

    if ($self->port) {
        my $port = $self->port;
        $port = "$port/tcp" unless $port =~ m{/};
        return $port;
    }

    if ($self->use_lowest_port) {
        my $ports = $container->request->exposed_ports;
        croak "No exposed ports configured" unless @$ports;

        # Find lowest port number
        my @sorted = sort {
            my ($a_num) = $a =~ /^(\d+)/;
            my ($b_num) = $b =~ /^(\d+)/;
            $a_num <=> $b_num;
        } @$ports;

        my $port = $sorted[0];
        $port = "$port/tcp" unless $port =~ m{/};
        return $port;
    }

    croak "No port specified and use_lowest_port is false";
}

1;
