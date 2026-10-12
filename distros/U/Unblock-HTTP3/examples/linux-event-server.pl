#!/usr/bin/env perl

use v5.36;
use strict;
use warnings;

use Linux::Event::Address;
use Linux::Event::IO::Sock::Dgram;
use Linux::Event::Kernel::Timer;
use Linux::Event::Loop;

use Net::QUIC::Driver;
use Unblock::HTTP3::Server;

my ($host, $port, $cert, $key) = @ARGV;
$host = '127.0.0.1' unless defined $host;
$port = 4433 unless defined $port;
$cert = 't/fixtures/localhost-cert.pem' unless defined $cert;
$key  = 't/fixtures/localhost-key.pem' unless defined $key;

die "use a concrete bind address, not a wildcard, in this example\n"
    if $host eq '0.0.0.0' || $host eq '::';

my $loop = Linux::Event::Loop->new;
my ($driver, $timer);
my @sessions;

# Application code: no UDP or QUIC details.
my $on_request = sub ($tx, $request) {
    $tx->respond(status => 200, body => "Hello from HTTP/3\n");
};

# Integration code: attach one HTTP/3 Server to each QUIC Connection.
my $activate = sub {
    while (my $quic = $driver->next_connection) {
        push @sessions, {
            quic => $quic,
            http => Unblock::HTTP3::Server->new(
                quic       => $quic,
                on_request => $on_request,
            ),
        };
    }

    for my $session (@sessions) {
        next unless $session->{quic}->ready;
        $session->{http}->start unless $session->{http}->started;
    }

    @sessions = grep { !$_->{quic}->closed } @sessions;
};

my $socket = Linux::Event::IO::Sock::Dgram->new(
    loop => $loop,
    host => $host,
    port => $port,

    on_datagram => sub ($socket, $bytes, $peer) {
        $driver->receive(
            $bytes,
            $socket->local->sockaddr,
            $peer->sockaddr,
        );
        $activate->();
    },

    on_drain => sub ($socket) {
        $driver->writable;
        $activate->();
    },

    on_error => sub ($socket, $error) {
        die "UDP error: $error\n";
    },
);

$driver = Net::QUIC::Driver->server(
    alpn             => 'h3',
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
                    $driver->timeout;
                    $activate->();
                },
            );
        }
    },
);

$driver->start;
say "HTTP/3 listening on $host:$port";
$loop->run;
