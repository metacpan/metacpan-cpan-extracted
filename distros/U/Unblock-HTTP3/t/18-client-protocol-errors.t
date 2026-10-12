use strict;
use warnings;

use FindBin ();
use IO::Select;
use IO::Socket::INET;
use Test2::V0;
use Time::HiRes qw(time);

use Net::QUIC;
use Net::QUIC::Driver;
use Unblock::HTTP3::Client;
use Unblock::HTTP3::Connection;

is(
    $Net::QUIC::VERSION,
    '0.04',
    'client protocol error tests use released Net::QUIC 0.04',
);

my $cert_file = "$FindBin::Bin/fixtures/localhost-cert.pem";
my $key_file = "$FindBin::Bin/fixtures/localhost-key.pem";

sub make_udp_socket {
    my $socket = IO::Socket::INET->new(
        LocalAddr => '127.0.0.1',
        LocalPort => 0,
        Proto     => 'udp',
    );

    die "could not create loopback UDP socket: $!"
        unless defined $socket;

    return $socket;
}

sub send_datagram {
    my ($socket, $datagram) = @_;

    my $bytes = $datagram->data;
    my $sent = send(
        $socket,
        $bytes,
        0,
        $datagram->peer,
    );

    die "loopback UDP send failed: $!"
        unless defined $sent;
    die "loopback UDP send was partial"
        if $sent != length($bytes);

    return 1;
}

sub make_pair {
    my $server_socket = make_udp_socket();
    my $client_socket = make_udp_socket();

    my $server_local = getsockname($server_socket);
    my $client_local = getsockname($client_socket);

    my ($server_deadline, $client_deadline);

    my $server_driver = Net::QUIC::Driver->server(
        alpn             => 'h3',
        certificate_file => $cert_file,
        private_key_file => $key_file,

        send => sub {
            my ($datagram) = @_;
            return send_datagram($server_socket, $datagram);
        },

        set_timeout => sub {
            my ($after) = @_;
            $server_deadline = defined($after)
                ? time() + $after
                : undef;
            return;
        },
    );

    my $client_driver = Net::QUIC::Driver->client(
        local       => $client_local,
        peer        => $server_local,
        alpn        => 'h3',
        server_name => 'localhost',
        ca_file     => $cert_file,

        send => sub {
            my ($datagram) = @_;
            return send_datagram($client_socket, $datagram);
        },

        set_timeout => sub {
            my ($after) = @_;
            $client_deadline = defined($after)
                ? time() + $after
                : undef;
            return;
        },
    );

    my $client_quic = $client_driver->connection;
    my $selector = IO::Select->new(
        $client_socket,
        $server_socket,
    );

    my $service_once = sub {
        my ($hard_deadline) = @_;

        my $now = time();

        if (defined($server_deadline) && $server_deadline <= $now) {
            $server_deadline = undef;
            $server_driver->timeout;
        }

        $now = time();

        if (defined($client_deadline) && $client_deadline <= $now) {
            $client_deadline = undef;
            $client_driver->timeout;
        }

        $now = time();
        my $wait = 0.02;

        for my $deadline (
            $server_deadline,
            $client_deadline,
            $hard_deadline,
        ) {
            next unless defined $deadline;

            my $remaining = $deadline - $now;
            $remaining = 0 if $remaining < 0;
            $wait = $remaining if $remaining < $wait;
        }

        for my $socket ($selector->can_read($wait)) {
            my $bytes = '';
            my $peer = recv(
                $socket,
                $bytes,
                65_535,
                0,
            );

            die "loopback UDP receive failed: $!"
                unless defined $peer;

            my $local = getsockname($socket);
            die "could not read loopback UDP local address: $!"
                unless defined $local;

            if (fileno($socket) == fileno($server_socket)) {
                $server_driver->receive(
                    $bytes,
                    $local,
                    $peer,
                );
            } else {
                $client_driver->receive(
                    $bytes,
                    $local,
                    $peer,
                );
            }
        }

        return;
    };

    my $run_until = sub {
        my ($condition) = @_;

        my $hard_deadline = time() + 10;

        while (time() < $hard_deadline) {
            return 1 if $condition->();
            $service_once->($hard_deadline);
        }

        return $condition->() ? 1 : 0;
    };

    $server_driver->start;
    $client_driver->start;

    my $server_quic;

    ok(
        $run_until->(sub {
            $server_quic ||= $server_driver->next_connection;

            return defined($server_quic)
                && $server_quic->ready
                && $client_quic->ready;
        }),
        'raw server completes h3 TLS handshake with client',
    );

    my $client_h3 = Unblock::HTTP3::Client->new(
        quic => $client_quic,
    );

    $client_h3->start;

    my $close = sub {
        close $client_socket;
        close $server_socket;
        return;
    };

    return {
        client_quic => $client_quic,
        client_h3   => $client_h3,
        server_quic => $server_quic,
        run_until   => $run_until,
        close       => $close,
    };
}

{
    my $pair = make_pair();

    my $stream = $pair->{server_quic}->open_uni_stream;
    ok(defined($stream), 'raw server opens unauthorized push stream');

    $stream->send("\x01\x00");

    ok(
        $pair->{run_until}->(sub {
            return $pair->{client_h3}->failed;
        }),
        'push stream without MAX_PUSH_ID fails HTTP/3 client connection',
    );

    is(
        $pair->{client_h3}->error_code,
        0x0108,
        'unauthorized push stream uses H3_ID_ERROR',
    );

    like(
        $pair->{client_h3}->error,
        qr/push stream without advertised push capacity/i,
        'unauthorized push records why push was not permitted',
    );

    $pair->{close}->();
}

{
    my $pair = make_pair();

    my $stream = $pair->{server_quic}->open_bidi_stream;
    ok(defined($stream), 'raw server opens forbidden bidirectional stream');

    $stream->send("\x00");

    ok(
        $pair->{run_until}->(sub {
            return $pair->{client_h3}->failed;
        }),
        'server-initiated bidirectional stream fails HTTP/3 client connection',
    );

    is(
        $pair->{client_h3}->error_code,
        0x0103,
        'server-initiated bidirectional stream uses H3_STREAM_CREATION_ERROR',
    );

    $pair->{close}->();
}

done_testing;
