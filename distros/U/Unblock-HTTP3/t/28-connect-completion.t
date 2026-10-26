use strict;
use warnings;

use FindBin ();
use IO::Select;
use IO::Socket::INET;
use Scalar::Util qw(refaddr);
use Test2::V0;
use Time::HiRes qw(time);

use Unblock::HTTP3::Capsule;
use Unblock::HTTP3::Client;
use Unblock::HTTP3::Connection;
use Unblock::HTTP3::Server;
use Net::QUIC;
use Net::QUIC::Driver;
use Uniform::HTTP::Request;
use Uniform::HTTP::Response;

ok($Net::QUIC::VERSION >= 0.05, 'vertical slice requires Net::QUIC 0.05 or newer');

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
        my $peer = recv($socket, $bytes, 65535, 0);

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

my $client_completes = 0;
my $client_finishes = 0;
my $server_finishes = 0;

my $client_h3 = Unblock::HTTP3::Client->new(quic => $client_quic);
my $server_h3 = Unblock::HTTP3::Server->new(
    quic => $server_quic, enable_extended_connect => 1,
);
$client_h3->start;
$server_h3->start;

ok(run_until(sub { $client_h3->peer_settings_received
                && $server_h3->peer_settings_received }),
    'both peers exchange HTTP3 SETTINGS');

ok($client_h3->peer_extended_connect_enabled,
    'peer permits Extended CONNECT');

my $request = Uniform::HTTP::Request->new(
    method => 'CONNECT',
    protocol => 'completion-test',
    scheme => 'https',
    authority => 'localhost',
    target => '/completion-ordering',
);
my $client_tx = $client_h3->request(
    $request,
    stream_body => 1,
    receive_body => 'stream',
    on_complete => sub { ++$client_completes },
    on_finish => sub { ++$client_finishes },
);
isa_ok($client_tx, ['Unblock::HTTP3::Transaction']);
my $client_writer = $client_tx->request_body;
isa_ok($client_writer, ['Unblock::HTTP3::Body::Stream']);

my $server_tx;
ok(run_until(sub {
    $server_tx ||= $server_h3->next_transaction;
    return defined $server_tx;
}), 'server receives incomplete CONNECT request');

my $server_writer = $server_tx->response_body;
isa_ok($server_writer, ['Unblock::HTTP3::Body::Stream']);
$server_writer->write('server-response');
$server_writer->complete;

my $received_response = '';
my $response_completed = run_until(sub {
    my $response = $client_tx->response;
    my $reader = $client_tx->_incoming_body_reader('response');
    if ($reader) {
        while (defined(my $bytes = $reader->next_chunk)) {
            $received_response .= $bytes;
        }
    }
    return $response && $response->is_complete
        && $reader && $reader->is_complete;
});
is($received_response, 'server-response',
    'incoming streaming response body consumed before local FIN');
if (!$response_completed) {
    my $res = $client_tx->response;
    my $reader = $client_tx->_incoming_body_reader('response');
    diag("pre-FIN state: tx=" . $client_tx->state
        . " response=" . ($res ? $res->is_complete : 'none')
        . " reader=" . ($reader ? $reader->is_complete : 'none')
        . " server=" . $server_tx->state);
}
ok($response_completed,
    'response and incoming reader complete before Client request FIN');

ok(!$client_writer->is_complete,
    'outgoing Client request writer remains open');
is($client_tx->state, 'active',
    'CONNECT Transaction must remain active before local FIN');

# No more network reads or QUIC timer callbacks between these assertions.
# Previously the native FIN write checked completion before the writer's
# complete bit was committed. It never rechecked once that bit became true.
$client_writer->complete;
ok($client_writer->is_complete, 'local request FIN committed');
is($client_tx->state, 'complete',
    'CONNECT completes immediately after final writer state mutation');
is($client_completes, 1, 'on_complete fires exactly once');
is($client_finishes, 1, 'on_finish fires exactly once');

ok(run_until(sub { return $server_tx->is_terminal }),
    'server also completes after receiving local request FIN');
ok($server_tx->is_complete, 'server finishes successfully');
is($client_completes, 1, 'no repeated completion after QUIC peer processing');
is($client_finishes, 1, 'no repeated finish after QUIC peer processing');
is($client_h3->failed, 0, 'client H3 connection remains healthy');
is($server_h3->failed, 0, 'server H3 connection remains healthy');

close $client_socket;
close $server_socket;
done_testing;
