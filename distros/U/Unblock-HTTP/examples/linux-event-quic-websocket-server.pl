#!/usr/bin/env perl
use v5.36;
use strict;
use warnings;

use Linux::Event::Address;
use Linux::Event::IO::Sock::Dgram;
use Linux::Event::Kernel::Timer;
use Linux::Event::Loop;
use Unblock::HTTP::QUIC;
use Unblock::HTTP::Server;

my ($host, $port, $cert, $key) = @ARGV;
$host = '127.0.0.1' unless defined $host;
$port = 4433 unless defined $port;
die "usage: $0 HOST PORT CERT.pem KEY.pem\n"
    unless defined($cert) && defined($key);
die "use a concrete bind address, not a wildcard, in this example\n"
    if $host eq '0.0.0.0' || $host eq '::';
die "port must be 1..65535\n"
    unless $port =~ /\A[0-9]+\z/ && $port >= 1 && $port <= 65535;

my $loop = Linux::Event::Loop->new;

# APPLICATION CODE: HTTP3 and WebSocket callbacks are the same as for
# the HTTP1/HTTP2 Server. No application packet or QUIC stream handling.
my $server = Unblock::HTTP::Server->new(
    http3 => { websocket => 1 },
    defer => sub ($callback) {
        # Required by HTTP3: do not reenter the parser during receive.
        $loop->defer($callback);
    },
    on_request => sub ($tx, $request) {
        $tx->respond(status => 200, body => "HTTP/3 is still available\n");
    },
    on_websocket => sub ($tx, $request) {
        # Reject other WebSocket targets with an HTTP 403 on that QUIC stream.
        return unless $request->target eq '/ws';
        return {
            on_message => sub ($ws, $payload, $type) {
                $type eq 'text'
                    ? $ws->send_text("echo:$payload")
                    : $ws->send_binary($payload);
            },
        };
    },
);

# ADAPTER CODE: the framework retains one UDP socket and one replaceable
# timer. Unblock::HTTP::QUIC owns the Net::QUIC Driver and attached H3
# Server engines; neither application callback touches those details.
my ($http, $timer);
my $socket = Linux::Event::IO::Sock::Dgram->new(
    loop => $loop,
    host => $host,
    port => $port,
    on_datagram => sub ($socket, $bytes, $peer) {
        $http->receive($bytes, $socket->local->sockaddr, $peer->sockaddr);
    },
    on_drain => sub ($socket) {
        $http->writable;
    },
    on_error => sub ($socket, $error) {
        die "UDP error: $error\n";
    },
);

$http = Unblock::HTTP::QUIC->server(
    server => $server,
    certificate_file => $cert,
    private_key_file => $key,
    send => sub ($datagram) {
        return $socket->send(
            $datagram->data,
            to => Linux::Event::Address->new($datagram->peer),
        );
    },
    set_timeout => sub ($seconds) {
        $timer->cancel if defined($timer) && $timer->is_active;
        undef $timer;
        if (defined $seconds) {
            $timer = Linux::Event::Kernel::Timer->new(
                loop => $loop,
                after => $seconds,
                on_timer => sub ($timer_object) {
                    undef $timer;
                    $http->timeout;
                },
            );
        }
    },
);

$http->start;
say "HTTP3: https://$host:$port/";
say "WebSocket: wss://$host:$port/ws (HTTP/3 Extended CONNECT)";
say "A WebSocket client must negotiate HTTP/3 and trust the supplied TLS cert.";
$loop->run;
