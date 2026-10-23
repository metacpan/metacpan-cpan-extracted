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

my $loop = Linux::Event::Loop->new;
my ($http, $timer);

# APPLICATION CODE: identical to the TCP example, including Transaction.
my $server = Unblock::HTTP::Server->new(
    http3 => {},
    on_request => sub ($tx, $request) {
        $tx->respond(status => 200, body => "hello from Unblock::HTTP/3\n");
    },
);

# ADAPTER CODE: one UDP socket and one replaceable QUIC timer.
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
    certificate_file => $cert,
    private_key_file => $key,
    server => $server,

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
say "HTTP/3 listening on $host:$port";
$loop->run;
