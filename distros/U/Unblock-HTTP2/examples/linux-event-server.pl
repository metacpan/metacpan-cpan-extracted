#!/usr/bin/env perl
use v5.36;
use strict;
use warnings;

use Linux::Event::IO::Sock::Listener;
use Linux::Event::IO::Sock::Stream;
use Linux::Event::Loop;
use Unblock::HTTP2::Server;

# ADAPTER CODE: HTTP/2 lives inside a normal Linux::Event stream.
package Example::HTTP2Stream;
use parent 'Linux::Event::IO::Sock::Stream';
use Scalar::Util qw(weaken);

sub new ($class, %args) {
    my $self = $class->SUPER::new(%args);
    my $stream = $self;
    weaken($stream);

    $self->{http2} = Unblock::HTTP2::Server->new(
        transport => $self,
        on_request => sub ($tx, $request) {
            $stream->on_http_request($tx, $request) if $stream;
        },
    );
    return $self;
}

sub on_data ($self, $bytes) {
    $self->{http2}->input($bytes);
}

sub on_eof ($self) {
    my $http = $self->{http2};
    $http->input_eof unless $http->is_closed;
}

sub on_error ($self, $error) {
    $self->{http2}->transport_error("$error");
}

sub on_drain ($self) {
    $self->{http2}->resume_output;
}

sub unblock_send ($self, $bytes) {
    my $ready = $self->write($bytes);
    die "Linux::Event stream closed during HTTP/2 output\n" if $self->is_closed;
    return $ready;
}

sub unblock_finish ($self) {
    $self->end;
}

sub unblock_abort ($self, $reason) {
    $self->close;
}

sub on_http_request ($self, $tx, $request) {
    die "on_http_request() must be implemented\n";
}

# APPLICATION CODE: request handling, not framework plumbing.
package Example::HelloHTTP2Stream;
use parent -norequire, 'Example::HTTP2Stream';

sub on_http_request ($self, $tx, $request) {
    $tx->respond(
        status => 200,
        headers => [ [ 'Content-Type' => 'text/plain' ] ],
        body => "hello from Linux::Event HTTP/2\n",
    );
}

package main;

my $port = shift // 8080;
die "usage: $0 [PORT]\n"
    unless $port =~ /\A[0-9]+\z/ && $port >= 1 && $port <= 65535;

my $loop = Linux::Event::Loop->new;

my $listener = Linux::Event::IO::Sock::Listener->new(
    loop => $loop,
    host => '127.0.0.1',
    port => $port,
    stream => { class => 'Example::HelloHTTP2Stream' },
);

print "HTTP/2 prior-knowledge server listening on ", $listener->port, "\n";
print "Test with: curl --http2-prior-knowledge http://127.0.0.1:$port/\n";
$loop->run;
