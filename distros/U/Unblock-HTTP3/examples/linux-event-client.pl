#!/usr/bin/env perl

use v5.36;
use strict;
use warnings;

use Linux::Event::IO::Sock::Dgram;
use Linux::Event::Kernel::Timer;
use Linux::Event::Loop;

use Net::QUIC::Driver;
use Unblock::HTTP3::Client;

my ($host, $port, $ca_file) = @ARGV;
$host    = '127.0.0.1' unless defined $host;
$port    = 4433 unless defined $port;
$ca_file = 't/fixtures/localhost-cert.pem' unless defined $ca_file;

my $loop = Linux::Event::Loop->new;
my ($driver, $quic, $http, $timer);
my $requested = 0;

# Application code: one ordinary HTTP request.
my $request = sub {
    return unless defined($quic) && $quic->ready;

    if (!defined $http) {
        $http = Unblock::HTTP3::Client->new(quic => $quic);
        $http->start;
    }

    return if $requested++;

    $http->request(
        method    => 'GET',
        target    => '/',
        scheme    => 'https',
        authority => 'localhost',

        on_response => sub ($tx, $response) {
            say "HTTP/3 " . $response->status;
        },

        on_body => sub ($tx, $response, $bytes) {
            print $bytes;
        },

        on_complete => sub ($tx) {
            $loop->stop;
        },

        on_error => sub ($tx, $error) {
            warn "HTTP/3 request failed: $error\n";
            $loop->stop;
        },
    );
};

# Integration code: one UDP socket and one replaceable QUIC timer.
my $socket = Linux::Event::IO::Sock::Dgram->connect(
    loop => $loop,
    host => $host,
    port => $port,

    on_ready => sub ($socket) {
        $driver = Net::QUIC::Driver->client(
            local       => $socket->local->sockaddr,
            peer        => $socket->peer->sockaddr,
            alpn        => 'h3',
            server_name => 'localhost',
            ca_file     => $ca_file,

            send => sub ($datagram) {
                return $socket->send($datagram->data);
            },

            set_timeout => sub ($seconds) {
                $timer->cancel if defined($timer) && $timer->is_active;
                undef $timer;

                if (defined $seconds) {
                    $timer = Linux::Event::Kernel::Timer->new(
                        loop  => $loop,
                        after => $seconds,

                        on_timer => sub ($timer_object) {
                            undef $timer;
                            $driver->timeout;
                            $request->();
                        },
                    );
                }
            },
        );

        $quic = $driver->connection;
        $driver->start;
        $request->();
    },

    on_datagram => sub ($socket, $bytes, $peer) {
        return unless defined $driver;

        $driver->receive(
            $bytes,
            $socket->local->sockaddr,
            $peer->sockaddr,
        );
        $request->();
    },

    on_drain => sub ($socket) {
        return unless defined $driver;
        $driver->writable;
        $request->();
    },

    on_error => sub ($socket, $error) {
        die "UDP error: $error\n";
    },
);

$loop->run;
$socket->close if $socket->is_active;
