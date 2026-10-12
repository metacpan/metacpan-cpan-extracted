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
use Unblock::HTTP3::Server;
use Uniform::HTTP::Request;

is($Net::QUIC::VERSION, '0.04', 'HTTP Datagrams use released Net::QUIC 0.04');

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

sub send_udp {
    my ($socket, $datagram) = @_;

    my $bytes = $datagram->data;
    my $sent = send($socket, $bytes, 0, $datagram->peer);

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
    transport        => {
        max_datagram_frame_size => 65_535,
    },
    send => sub {
        my ($datagram) = @_;
        return send_udp($server_socket, $datagram);
    },
    set_timeout => sub {
        my ($after) = @_;
        $server_deadline = defined($after) ? time() + $after : undef;
        return;
    },
);

my $client_driver = Net::QUIC::Driver->client(
    local       => $client_local,
    peer        => $server_local,
    alpn        => 'h3',
    server_name => 'localhost',
    ca_file     => $cert_file,
    transport   => {
        max_datagram_frame_size => 65_535,
    },
    send => sub {
        my ($datagram) = @_;
        return send_udp($client_socket, $datagram);
    },
    set_timeout => sub {
        my ($after) = @_;
        $client_deadline = defined($after) ? time() + $after : undef;
        return;
    },
);

my $selector = IO::Select->new($server_socket, $client_socket);

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

my $client_quic = $client_driver->connection;
my $server_quic;

ok(
    run_until(sub {
        $server_quic ||= $server_driver->next_connection;

        return $server_quic
            && $client_quic->ready
            && $server_quic->ready;
    }),
    'QUIC/TLS handshake completes with DATAGRAM transport enabled',
);

my $client_h3 = Unblock::HTTP3::Client->new(
    quic                  => $client_quic,
    enable_http_datagrams => 1,
);

my $server_h3 = Unblock::HTTP3::Server->new(
    quic                    => $server_quic,
    enable_extended_connect => 1,
    enable_http_datagrams   => 1,
    max_buffered_datagrams  => 1,
    datagram_request        => sub {
        my ($connection, $request) = @_;
        return defined($request->protocol)
            && $request->protocol eq 'datagram-test'
            ? 1
            : 0;
    },
);

$client_h3->start;
$server_h3->start;

ok(
    run_until(sub {
        return $client_h3->peer_settings_received
            && $server_h3->peer_settings_received;
    }),
    'both HTTP/3 endpoints receive peer SETTINGS',
);

ok($client_h3->http_datagrams_enabled,
    'client advertises SETTINGS_H3_DATAGRAM');
ok($server_h3->http_datagrams_enabled,
    'server advertises SETTINGS_H3_DATAGRAM');
ok($client_h3->peer_http_datagrams_enabled,
    'client sees server SETTINGS_H3_DATAGRAM');
ok($server_h3->peer_http_datagrams_enabled,
    'server sees client SETTINGS_H3_DATAGRAM');
ok($client_h3->can_send_http_datagrams,
    'client can send negotiated HTTP Datagrams');
ok($server_h3->can_send_http_datagrams,
    'server can send negotiated HTTP Datagrams');
ok($client_h3->can_receive_http_datagrams,
    'client can receive negotiated HTTP Datagrams');
ok($server_h3->can_receive_http_datagrams,
    'server can receive negotiated HTTP Datagrams');
is($server_h3->datagram_receive_drops, 0,
    'HTTP Datagram receive drop counter starts at zero');

my $request = Uniform::HTTP::Request->new(
    method    => 'CONNECT',
    protocol  => 'datagram-test',
    scheme    => 'https',
    authority => 'localhost',
    target    => '/datagrams',
);

my $client_tx = $client_h3->request(
    $request,
    datagrams => 1,
);

ok($client_tx->datagrams_enabled,
    'client explicitly enables datagram semantics on the request');

my $server_tx;

ok(
    run_until(sub {
        $server_tx ||= $server_h3->next_transaction;
        return defined $server_tx;
    }),
    'server receives the datagram-capable request',
);

ok($server_tx->datagrams_enabled,
    'server policy enables datagram semantics before delivery to the application');

cmp_ok(
    $client_tx->max_datagram_payload_size,
    '>',
    0,
    'Transaction exposes current HTTP Datagram payload capacity',
);
cmp_ok(
    $client_tx->max_datagram_payload_size,
    '<',
    $client_quic->max_datagram_payload_size,
    'HTTP Datagram capacity accounts for Quarter Stream ID overhead',
);

ok(
    $client_tx->send_datagram('client-one'),
    'client queues an HTTP Datagram',
);

my $server_payload;

ok(
    run_until(sub {
        $server_payload = $server_tx->next_datagram;
        return defined $server_payload;
    }),
    'server receives the client HTTP Datagram',
);
is($server_payload, 'client-one',
    'server receives only the HTTP Datagram payload');

ok(
    $server_tx->send_datagram('server-one'),
    'server queues an HTTP Datagram',
);

my $client_payload;

ok(
    run_until(sub {
        $client_payload = $client_tx->next_datagram;
        return defined $client_payload;
    }),
    'client receives the server HTTP Datagram',
);
is($client_payload, 'server-one',
    'client receives only the HTTP Datagram payload');

my @callback_payloads;
$client_tx->on_datagram(sub {
    my ($transaction, $bytes) = @_;
    push @callback_payloads, $bytes;
    return;
});

ok(
    $server_tx->send_datagram('callback-data'),
    'server sends a callback-delivered HTTP Datagram',
);

ok(
    run_until(sub { return @callback_payloads == 1 }),
    'Transaction callback receives an HTTP Datagram',
);
is(\@callback_payloads, ['callback-data'],
    'callback receives the unwrapped payload');

ok(
    $client_tx->send_datagram(''),
    'zero-length HTTP Datagram payload is accepted',
);

my $empty_payload;
ok(
    run_until(sub {
        $empty_payload = $server_tx->next_datagram;
        return defined $empty_payload;
    }),
    'server receives zero-length HTTP Datagram payload',
);
is($empty_payload, '',
    'zero-length HTTP Datagram payload is preserved');

ok(
    $client_tx->send_datagram('queue-one'),
    'first buffered HTTP Datagram is accepted',
);
ok(
    $client_tx->send_datagram('queue-two'),
    'second buffered HTTP Datagram is accepted by the transport',
);

ok(
    run_until(sub { return $server_h3->datagram_receive_drops == 1 }),
    'HTTP layer drops excess unreliable datagram instead of growing its queue',
);

my $bounded_payload = $server_tx->next_datagram;
ok(
    defined($bounded_payload)
        && ($bounded_payload eq 'queue-one' || $bounded_payload eq 'queue-two'),
    'bounded queue retains exactly one of the unordered datagrams',
);
is($server_tx->next_datagram, undef,
    'bounded Transaction queue contains only one datagram');
is($server_h3->datagram_receive_drops, 1,
    'HTTP Datagram queue overflow is observable');

my $unsupported_request = Uniform::HTTP::Request->new(
    method    => 'CONNECT',
    protocol  => 'not-datagram-enabled',
    scheme    => 'https',
    authority => 'localhost',
    target    => '/unsupported',
);

my $unsupported_client_tx = $client_h3->request(
    $unsupported_request,
    datagrams => 1,
);
my $unsupported_server_tx;

ok(
    run_until(sub {
        $unsupported_server_tx ||= $server_h3->next_transaction;
        return defined $unsupported_server_tx;
    }),
    'server receives request whose protocol did not opt into datagrams',
);

ok(!$unsupported_server_tx->datagrams_enabled,
    'server policy leaves unsupported request without datagram semantics');

ok(
    $unsupported_client_tx->send_datagram('must-fail-stream'),
    'client can put the protocol-invalid datagram on the negotiated wire',
);

ok(
    run_until(sub { return $unsupported_server_tx->is_terminal }),
    'server terminates the request that received an unsupported HTTP Datagram',
);
like(
    $unsupported_server_tx->error,
    qr/without datagram semantics/,
    'unsupported HTTP Datagram reports the semantic error',
);

ok(
    $client_quic->send_datagram(''),
    'raw malformed QUIC DATAGRAM enters the HTTP/3 connection',
);

ok(
    run_until(sub { return $server_h3->failed }),
    'missing Quarter Stream ID fails the HTTP/3 connection',
);
is($server_h3->error_code, 0x33,
    'malformed HTTP Datagram uses H3_DATAGRAM_ERROR');

done_testing;
