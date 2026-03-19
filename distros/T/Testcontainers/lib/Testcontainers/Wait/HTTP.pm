package Testcontainers::Wait::HTTP;
# ABSTRACT: Wait strategy for HTTP endpoints

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

    # Wait for HTTP 200 on /
    my $wait = Testcontainers::Wait::for_http('/');

    # Wait with custom options
    my $wait = Testcontainers::Wait::for_http('/health',
        port        => '8080/tcp',
        status_code => 200,
        method      => 'GET',
    );

=head1 DESCRIPTION

Waits for an HTTP endpoint to return a successful response. Equivalent to
Go's C<wait.ForHTTP()>.

This wait strategy makes a raw HTTP request (without depending on LWP or
HTTP::Tiny) to keep dependencies minimal, matching WWW::Docker's approach.

=cut

has path => (
    is      => 'ro',
    default => '/',
);

=attr path

HTTP path to request. Default: C</>.

=cut

has port => (
    is      => 'ro',
    default => undef,
);

=attr port

Container port to connect to. If not set, uses the lowest exposed port.

=cut

has status_code => (
    is      => 'ro',
    default => 200,
);

=attr status_code

Expected HTTP status code. Default: 200.

=cut

has method => (
    is      => 'ro',
    default => 'GET',
);

=attr method

HTTP method. Default: C<GET>.

=cut

has body => (
    is      => 'ro',
    default => undef,
);

has headers => (
    is      => 'ro',
    default => sub { {} },
);

has tls => (
    is      => 'ro',
    default => 0,
);

has response_matcher => (
    is      => 'ro',
    default => undef,
);

=attr response_matcher

Optional coderef that receives the response body and returns true/false.

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

    my $scheme = $self->tls ? 'https' : 'http';
    my $url = sprintf("%s://%s:%s%s", $scheme, $host, $mapped_port, $self->path);

    $log->tracef("HTTP check: %s %s", $self->method, $url);

    # Use HTTP::Tiny if available, fallback to raw socket
    my ($status, $response_body) = $self->_do_http_request($host, $mapped_port);

    unless (defined $status) {
        return 0;
    }

    $log->tracef("HTTP response: %d", $status);

    if ($status != $self->status_code) {
        return 0;
    }

    if ($self->response_matcher) {
        return $self->response_matcher->($response_body) ? 1 : 0;
    }

    return 1;
}

=method check($container)

Make an HTTP request and check the response. Returns true/false.

=cut

sub _do_http_request {
    my ($self, $host, $port) = @_;

    # Try HTTP::Tiny first (commonly available)
    if (eval { require HTTP::Tiny; 1 }) {
        my $http = HTTP::Tiny->new(timeout => 3);

        # Try both IPv6 and IPv4 to handle Docker port mapping on macOS
        my @hosts = $host eq 'localhost' ? ('::1', '127.0.0.1') : ($host);
        for my $try_host (@hosts) {
            my $url_host = $try_host =~ /:/ ? "[$try_host]" : $try_host;
            my $url = sprintf("%s://%s:%s%s",
                $self->tls ? 'https' : 'http', $url_host, $port, $self->path);

            my %request_opts;
            $request_opts{headers} = $self->headers if %{$self->headers};
            $request_opts{content} = $self->body if defined $self->body;

            my $response = eval { $http->request($self->method, $url, \%request_opts) };
            next if $@ || !$response;
            next if $response->{status} == 599;  # connection error, try next host

            return ($response->{status}, $response->{content});
        }
        return (undef, undef);
    }

    # Fallback to raw socket HTTP
    my $sock = IO::Socket::INET->new(
        PeerAddr => $host,
        PeerPort => $port,
        Proto    => 'tcp',
        Timeout  => 3,
    );
    return (undef, undef) unless $sock;

    my $path = $self->path;
    my $method = $self->method;
    my $request = "$method $path HTTP/1.0\r\nHost: $host:$port\r\n";

    for my $key (keys %{$self->headers}) {
        $request .= "$key: $self->{headers}{$key}\r\n";
    }

    if (defined $self->body) {
        my $len = length($self->body);
        $request .= "Content-Length: $len\r\n\r\n$self->{body}";
    } else {
        $request .= "\r\n";
    }

    print $sock $request;

    my $response = '';
    while (my $line = <$sock>) {
        $response .= $line;
    }
    close($sock);

    if ($response =~ m{^HTTP/\d\.\d (\d+)}) {
        my $status = $1;
        my ($body) = $response =~ m{\r\n\r\n(.*)$}s;
        return ($status, $body // '');
    }

    return (undef, undef);
}

sub _resolve_port {
    my ($self, $container) = @_;

    if ($self->port) {
        my $port = $self->port;
        $port = "$port/tcp" unless $port =~ m{/};
        return $port;
    }

    # Use lowest exposed port
    my $ports = $container->request->exposed_ports;
    croak "No exposed ports configured and no port specified" unless @$ports;

    my @sorted = sort {
        my ($a_num) = $a =~ /^(\d+)/;
        my ($b_num) = $b =~ /^(\d+)/;
        $a_num <=> $b_num;
    } @$ports;

    my $port = $sorted[0];
    $port = "$port/tcp" unless $port =~ m{/};
    return $port;
}

1;
