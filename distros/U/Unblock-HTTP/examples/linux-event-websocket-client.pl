#!/usr/bin/env perl
use v5.36;
use strict;
use warnings;

use Linux::Event::Loop;
use Linux::Event::Kernel::Timer;
use Unblock::HTTP::Client;
use Linux::Event::IO::Sock::Stream;

# ADAPTER CODE: the host creates a connected TCP Stream and forwards
# bytes to whichever real engine currently owns this socket. Only HTTP1
# Upgrade replaces the input consumer. H2 WebSockets stay in H2 streams.
package Example::WebSocketClientStream;
use parent 'Linux::Event::IO::Sock::Stream';

sub on_ready ($self) {
    my $ready = delete $self->{unblock_ready}
        or die "missing HTTP client readiness callback\n";
    $self->{http} = $ready->(
        transport => $self, alpn => $self->{unblock_alpn},
    );
}

sub unblock_upgrade ($self, $websocket) {
    die "already upgraded\n" if $self->{websocket};
    $self->{websocket} = $websocket;
    return;
}

sub consumer ($self) { $self->{websocket} || $self->{http} }
sub on_data ($self, $bytes) { $self->consumer->input($bytes) }
sub on_eof ($self) {
    my $engine = $self->consumer;
    $engine->input_eof if $engine && $engine->want_read;
}
sub on_error ($self, $error) {
    my $engine = $self->consumer;
    $engine->transport_error("$error") if $engine;
}
sub on_drain ($self) {
    my $engine = $self->consumer;
    $engine->resume_output if $engine;
}
sub unblock_send ($self, $bytes) {
    my $ready = $self->write($bytes);
    die "socket closed while sending\n" if $self->is_closed;
    return $ready;
}
sub unblock_finish ($self) { $self->end }
sub unblock_abort ($self, $reason) { $self->close }

package main;

my ($host, $port, $protocol) = @ARGV;
$host //= '127.0.0.1';
$port //= 8080;
$protocol //= '1.1';
die "usage: $0 [HOST [PORT [1.1|2]]]\n"
    unless $protocol eq '1.1' || $protocol eq '2';
die "port must be 1..65535\n"
    unless $port =~ /\A[0-9]+\z/ && $port >= 1 && $port <= 65535;

my $loop = Linux::Event::Loop->new;
my @streams;

# APPLICATION CODE: one Client creates and pools connections. The WebSocket
# handlers only see WebSocket messages and the original HTTP Transaction.
my $client = Unblock::HTTP::Client->new(
    http1 => { websocket => 1 },
    http2 => { websocket => 1 },
    connect_stream => sub ($origin, $alpn_choices, $ready) {
        # ADAPTER FACTORY: cleartext local demo. For production WSS,
        # establish TLS and choose ALPN using $alpn_choices.
        my $stream = Example::WebSocketClientStream->connect(
            loop => $loop,
            host => $origin->{host},
            port => $origin->{port},
        );
        $stream->{unblock_ready} = $ready;
        $stream->{unblock_alpn} = $protocol eq '2' ? 'h2' : 'http/1.1';
        push @streams, $stream;
    },
    defer => sub ($callback) { $loop->defer($callback) },
);

my $watchdog = Linux::Event::Kernel::Timer->new(
    loop => $loop, after => 10,
    on_timer => sub ($timer) {
        warn "WebSocket example timed out\n";
        $loop->stop;
    },
);

my $operation = $client->connect_websocket(
    url => "ws://$host:$port/ws",
    http_version => $protocol,
    on_open => sub ($ws, $http_tx) {
        print "WebSocket connected via HTTP/$protocol\n";
        $ws->send_text('hello');
    },
    on_message => sub ($ws, $payload, $type) {
        print "WebSocket $type message: $payload\n";
        $ws->close;
    },
    on_close => sub ($ws, @details) {
        $loop->stop;
    },
    on_error => sub ($object, $error) {
        warn "WebSocket error: $error\n";
        $loop->stop;
    },
);
$loop->run;

$client->shutdown;
for my $stream (@streams) {
    $stream->close unless $stream->is_closed;
}
$watchdog->cancel if $watchdog->is_active;
