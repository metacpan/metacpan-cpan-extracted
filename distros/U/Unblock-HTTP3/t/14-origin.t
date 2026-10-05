use strict;
use warnings;

use FindBin ();
use IO::Select;
use IO::Socket::INET;
use Test2::V0;
use Time::HiRes qw(time);

use Net::QUIC;
use Net::QUIC::Driver;
use Unblock::HTTP3::Connection;
use Unblock::HTTP3::_Native;

is($Net::QUIC::VERSION, '0.04', 'ORIGIN loopback uses released Net::QUIC 0.04');

my $empty_native = Unblock::HTTP3::_Native->server(
    65_536,
    4_096,
    100,
    0,
    0,
    '',
);
isa_ok(
    $empty_native,
    ['Unblock::HTTP3::_Native::Connection'],
    'native server accepts an explicit empty ORIGIN frame payload',
);
undef $empty_native;

my $cert_file = "$FindBin::Bin/fixtures/localhost-cert.pem";
my $key_file = "$FindBin::Bin/fixtures/localhost-key.pem";

-f $cert_file or die "missing bundled loopback TLS certificate: $cert_file";
-f $key_file or die "missing bundled loopback TLS private key: $key_file";

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
my $selector = IO::Select->new($client_socket, $server_socket);

sub service_once {
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

    my $wait = 0.05;

    for my $deadline ($server_deadline, $client_deadline, $hard_deadline) {
        next unless defined $deadline;

        my $remaining = $deadline - $now;
        $remaining = 0 if $remaining < 0;
        $wait = $remaining if $remaining < $wait;
    }

    for my $socket ($selector->can_read($wait)) {
        my $bytes = '';
        my $peer = recv($socket, $bytes, 65_535, 0);

        die "loopback UDP receive failed: $!"
            unless defined $peer;

        my $local = getsockname($socket);
        die "could not read loopback UDP local address: $!"
            unless defined $local;

        if (fileno($socket) == fileno($server_socket)) {
            $server_driver->receive($bytes, $local, $peer);
        } else {
            $client_driver->receive($bytes, $local, $peer);
        }
    }

    return;
}

sub run_until {
    my ($condition) = @_;

    my $hard_deadline = time() + 10;

    while (time() < $hard_deadline) {
        return 1 if $condition->();
        service_once($hard_deadline);
    }

    return $condition->() ? 1 : 0;
}

$server_driver->start;
$client_driver->start;

my $server_quic;

ok(
    run_until(sub {
        $server_quic ||= $server_driver->next_connection;

        return $server_quic
            && $client_quic->ready
            && $server_quic->ready;
    }),
    'real QUIC/TLS handshake completes with h3 ALPN',
);

like(
    dies {
        Unblock::HTTP3::Connection->client(
            quic    => $client_quic,
            origins => [],
        );
    },
    qr/origins is only valid for a server connection/,
    'clients cannot advertise RFC 9412 ORIGIN frames',
);

like(
    dies {
        Unblock::HTTP3::Connection->server(
            quic    => $server_quic,
            origins => [ 'https://example.test/path' ],
        );
    },
    qr/origin must be an RFC 6454 ASCII serialization/,
    'server rejects a URI that is not an origin serialization',
);

my $client_h3 = Unblock::HTTP3::Connection->client(
    quic => $client_quic,
);

my $server_h3 = Unblock::HTTP3::Connection->server(
    quic => $server_quic,
    origins => [
        'https://example.test',
        'https://alt.example.test:8443',
    ],
);

is(
    $client_h3->peer_origins,
    undef,
    'peer origins are undefined before a complete ORIGIN frame arrives',
);

$client_h3->start;
$server_h3->start;

ok(
    run_until(sub {
        return defined $client_h3->peer_origins;
    }),
    'client receives the server RFC 9412 ORIGIN frame',
);

is(
    $client_h3->peer_origins,
    [
        'https://example.test',
        'https://alt.example.test:8443',
    ],
    'client exposes the advertised origin entries',
);

my $copy = $client_h3->peer_origins;
push @$copy, 'https://mutated.example';

is(
    $client_h3->peer_origins,
    [
        'https://example.test',
        'https://alt.example.test:8443',
    ],
    'peer_origins returns a defensive copy',
);

is(
    $server_h3->peer_origins,
    undef,
    'server does not invent peer origins when the client sends no ORIGIN frame',
);

ok(
    $client_h3->peer_settings_received
        && $server_h3->peer_settings_received,
    'ORIGIN exchange preserves ordinary HTTP/3 SETTINGS processing',
);

close $client_socket;
close $server_socket;

done_testing;
