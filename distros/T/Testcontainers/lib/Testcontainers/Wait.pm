package Testcontainers::Wait;
# ABSTRACT: Wait strategy factory for Testcontainers

use strict;
use warnings;
use Carp qw( croak );

use Testcontainers::Wait::HostPort;
use Testcontainers::Wait::HTTP;
use Testcontainers::Wait::Log;
use Testcontainers::Wait::HealthCheck;
use Testcontainers::Wait::Multi;

our $VERSION = '0.001';

use Exporter 'import';
our @EXPORT_OK = qw(
    for_listening_port
    for_exposed_port
    for_http
    for_log
    for_health_check
    for_all
);

=head1 SYNOPSIS

    use Testcontainers::Wait;

    # Wait for a specific port to be listening
    my $wait = Testcontainers::Wait::for_listening_port('80/tcp');

    # Wait for the lowest exposed port
    my $wait = Testcontainers::Wait::for_exposed_port();

    # Wait for an HTTP endpoint to return 200
    my $wait = Testcontainers::Wait::for_http('/');

    # Wait for an HTTP endpoint with custom options
    my $wait = Testcontainers::Wait::for_http('/health',
        port          => '8080/tcp',
        status_code   => 200,
        method        => 'GET',
    );

    # Wait for a log message
    my $wait = Testcontainers::Wait::for_log('ready to accept connections');

    # Wait for a log message matching regex
    my $wait = Testcontainers::Wait::for_log(qr/listening on port \d+/);

    # Wait for Docker health check
    my $wait = Testcontainers::Wait::for_health_check();

    # Combine multiple strategies (all must pass)
    my $wait = Testcontainers::Wait::for_all(
        Testcontainers::Wait::for_listening_port('5432/tcp'),
        Testcontainers::Wait::for_log('ready to accept connections'),
    );

=head1 DESCRIPTION

Factory module for creating wait strategies. Wait strategies determine when
a container is "ready" for use in tests. Inspired by the Go testcontainers
wait package.

=cut

sub for_listening_port {
    my ($port) = @_;
    croak "Port required" unless $port;
    return Testcontainers::Wait::HostPort->new(port => $port);
}

=func for_listening_port($port)

Wait for the specified port to be listening. The port should include the protocol
(e.g., C<80/tcp>). If no protocol is given, C</tcp> is assumed.

=cut

sub for_exposed_port {
    return Testcontainers::Wait::HostPort->new(use_lowest_port => 1);
}

=func for_exposed_port()

Wait for the lowest exposed port to be listening.

=cut

sub for_http {
    my ($path, %opts) = @_;
    return Testcontainers::Wait::HTTP->new(
        path => $path // '/',
        %opts,
    );
}

=func for_http($path, %opts)

Wait for an HTTP endpoint to return a successful response.

Options:

=over

=item * C<port> - Specific port to check (default: lowest exposed port)

=item * C<status_code> - Expected HTTP status code (default: 200)

=item * C<method> - HTTP method (default: GET)

=item * C<body> - Request body

=item * C<headers> - HashRef of HTTP headers

=item * C<tls> - Use HTTPS (default: false)

=back

=cut

sub for_log {
    my ($pattern, %opts) = @_;
    croak "Log pattern required" unless defined $pattern;
    return Testcontainers::Wait::Log->new(
        pattern     => $pattern,
        occurrences => $opts{occurrences} // 1,
    );
}

=func for_log($pattern, %opts)

Wait for a string or regex pattern to appear in container logs.

Options:

=over

=item * C<occurrences> - Number of times the pattern must occur (default: 1)

=back

=cut

sub for_health_check {
    return Testcontainers::Wait::HealthCheck->new;
}

=func for_health_check()

Wait for the Docker health check to report "healthy".

=cut

sub for_all {
    my (@strategies) = @_;
    croak "At least one strategy required" unless @strategies;
    return Testcontainers::Wait::Multi->new(strategies => \@strategies);
}

=func for_all(@strategies)

Combine multiple wait strategies. All must pass for the container to be
considered ready.

=cut

1;
