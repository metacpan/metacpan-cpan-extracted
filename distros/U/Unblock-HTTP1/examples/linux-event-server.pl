#!/usr/bin/env perl
use v5.36;
use strict;
use warnings;

use Linux::Event::IO::Sock::Listener;
use Linux::Event::IO::Sock::Stream;
use Linux::Event::Loop;
use Unblock::HTTP1::Server;

# ADAPTER CODE: HTTP lives inside the normal Linux::Event stream.
package Example::HTTPStream;
use parent 'Linux::Event::IO::Sock::Stream';
use Scalar::Util qw(weaken);

sub new ($class, %args) {
    my $self = $class->SUPER::new(%args);

    my $stream = $self;
    weaken($stream);

    $self->{http} = Unblock::HTTP1::Server->new(
        transport => $self,
        on_request => sub ($tx, $request) {
            $stream->on_http_request($tx, $request) if $stream;
        },
    );

    return $self;
}

sub on_data ($self, $bytes) {
    $self->{http}->input($bytes);
}

sub on_eof ($self) {
    my $http = $self->{http};
    $http->input_eof unless $http->is_closed || $http->is_switched;
}

sub on_error ($self, $error) {
    $self->{http}->transport_error("$error");
}

sub on_drain ($self) {
    $self->{http}->resume_output;
}

sub unblock_send ($self, $bytes) {
    my $ready = $self->write($bytes);
    # Linux::Event's hard output limit is a write failure, not congestion.
    # Do not report rejected bytes as accepted to Unblock.
    die "Linux::Event stream closed during write\n" if $self->is_closed;
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

# APPLICATION CODE: provide the request handler in a subclass.
package Example::HelloHTTPStream;
use parent -norequire, 'Example::HTTPStream';

sub on_http_request ($self, $tx, $request) {
    $tx->respond(
        status  => 200,
        headers => [ [ 'Content-Type' => 'text/plain' ] ],
        body    => "hello from Linux::Event\n",
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
    stream => { class => 'Example::HelloHTTPStream' },
);

print "listening on port ", $listener->port, "\n";
$loop->run;
