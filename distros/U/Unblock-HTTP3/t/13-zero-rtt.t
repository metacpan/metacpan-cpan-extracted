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

is($Net::QUIC::VERSION, '0.04',
    'HTTP/3 0-RTT test uses released Net::QUIC 0.04');

my $cert_file = "$FindBin::Bin/fixtures/localhost-cert.pem";
my $key_file = "$FindBin::Bin/fixtures/localhost-key.pem";

-f $cert_file or die "missing bundled loopback TLS certificate: $cert_file";
-f $key_file or die "missing bundled loopback TLS private key: $key_file";

sub make_socket {
    my $socket = IO::Socket::INET->new(
        LocalAddr => '127.0.0.1',
        LocalPort => 0,
        Proto     => 'udp',
    );
    die "could not create UDP socket: $!" unless $socket;
    return $socket;
}

sub send_datagram {
    my ($socket, $datagram) = @_;
    my $bytes = $datagram->data;
    my $sent = send($socket, $bytes, 0, $datagram->peer);
    die "UDP send failed: $!" unless defined $sent;
    die "partial UDP send" if $sent != length($bytes);
    return 1;
}

my $server_socket = make_socket();
my $server_local = getsockname($server_socket);
my $server_deadline;

my $server_driver = Net::QUIC::Driver->server(
    alpn              => 'h3',
    certificate_file  => $cert_file,
    private_key_file  => $key_file,
    accept_early_data => 1,
    transport => {
        max_datagram_frame_size => 65535,
    },
    send => sub {
        my ($datagram) = @_;
        return send_datagram($server_socket, $datagram);
    },
    set_timeout => sub {
        my ($after) = @_;
        $server_deadline = defined($after) ? time() + $after : undef;
        return;
    },
);

$server_driver->start;

my @clients;
my $selector = IO::Select->new($server_socket);

sub new_client {
    my (%args) = @_;

    my $socket = make_socket();
    my $local = getsockname($socket);
    my $deadline_box = [ undef ];

    my %driver_args = (
        local       => $local,
        peer        => $server_local,
        alpn        => 'h3',
        server_name => 'localhost',
        ca_file     => $cert_file,
        transport => {
            max_datagram_frame_size => 65535,
        },
        send => sub {
            my ($datagram) = @_;
            return send_datagram($socket, $datagram);
        },
        set_timeout => sub {
            my ($after) = @_;
            $deadline_box->[0] = defined($after) ? time() + $after : undef;
            return;
        },
    );

    $driver_args{early_data} = $args{early_data}
        if defined $args{early_data};

    my $driver = Net::QUIC::Driver->client(%driver_args);
    $driver->start;

    my $entry = {
        socket       => $socket,
        local        => $local,
        driver       => $driver,
        deadline_box => $deadline_box,
    };

    push @clients, $entry;
    $selector->add($socket);
    return $entry;
}

sub service_once {
    my ($hard_deadline) = @_;
    my $now = time();

    if (defined($server_deadline) && $server_deadline <= $now) {
        $server_deadline = undef;
        $server_driver->timeout;
    }

    for my $client (@clients) {
        my $deadline = $client->{deadline_box}[0];
        if (defined($deadline) && $deadline <= time()) {
            $client->{deadline_box}[0] = undef;
            $client->{driver}->timeout;
        }
    }

    $now = time();
    my $wait = 0.02;

    for my $deadline (
        $server_deadline,
        (map { $_->{deadline_box}[0] } @clients),
        $hard_deadline,
    ) {
        next unless defined $deadline;
        my $remaining = $deadline - $now;
        $remaining = 0 if $remaining < 0;
        $wait = $remaining if $remaining < $wait;
    }

    for my $socket ($selector->can_read($wait)) {
        my $bytes = '';
        my $peer = recv($socket, $bytes, 65535, 0);
        die "UDP receive failed: $!" unless defined $peer;
        my $local = getsockname($socket);

        if (fileno($socket) == fileno($server_socket)) {
            $server_driver->receive($bytes, $local, $peer);
            next;
        }

        my ($client) = grep {
            fileno($_->{socket}) == fileno($socket)
        } @clients;

        die "unknown client socket" unless $client;
        $client->{driver}->receive($bytes, $local, $peer);
    }

    return;
}

sub run_until {
    my ($condition, $seconds) = @_;
    $seconds = 5 unless defined $seconds;
    my $deadline = time() + $seconds;

    while (time() < $deadline) {
        return 1 if $condition->();
        service_once($deadline);
    }

    return $condition->() ? 1 : 0;
}

sub h3_client {
    my ($quic, %extra) = @_;
    return Unblock::HTTP3::Client->new(
        quic                  => $quic,
        enable_http_datagrams => 1,
        extension_settings    => { 84 => 7 },
        %extra,
    );
}

sub h3_server {
    my ($quic, %extra) = @_;
    return Unblock::HTTP3::Server->new(
        quic                    => $quic,
        enable_extended_connect => 1,
        enable_http_datagrams   => 1,
        extension_settings      => { 84 => 7 },
        datagram_request => sub {
            my ($connection, $request) = @_;
            return $request->target eq '/early' ? 1 : 0;
        },
        %extra,
    );
}

my $first = new_client();

my $first_server_quic;
ok(
    run_until(sub {
        $first_server_quic ||= $server_driver->next_connection;
        return $first->{driver}->connection->ready
            && defined($first_server_quic)
            && $first_server_quic->ready;
    }),
    'first QUIC handshake completes',
);

my $first_client_h3 = h3_client($first->{driver}->connection);
my $first_server_h3 = h3_server($first_server_quic);
$first_client_h3->start;
$first_server_h3->start;

ok(
    run_until(sub {
        return $first_client_h3->peer_settings_received
            && $first_server_h3->peer_settings_received;
    }),
    'first connection exchanges HTTP/3 SETTINGS',
);

my $remembered_peer = $first_client_h3->peer_settings_state;
my $remembered_local = $first_server_h3->local_settings_state;

ok(defined($remembered_peer), 'client exports remembered peer HTTP/3 SETTINGS');
ok(defined($remembered_local), 'server exports remembered local HTTP/3 SETTINGS');

my $quic_early;
ok(
    run_until(sub {
        $quic_early = $first->{driver}->connection->early_data_state;
        return defined $quic_early;
    }),
    'first connection exports QUIC early-data state',
);

my $second = new_client(early_data => $quic_early);
my $second_quic = $second->{driver}->connection;

is($second_quic->early_data_status, 'pending',
    'returning client begins a QUIC 0-RTT attempt');
ok(!$second_quic->ready, 'returning client is not handshake-ready yet');

my $second_client_h3 = h3_client(
    $second_quic,
    remembered_peer_settings => $remembered_peer,
);

ok($second_client_h3->using_remembered_peer_settings,
    'client initializes HTTP/3 from remembered peer SETTINGS');

$second_client_h3->start;

my $early_request = Uniform::HTTP::Request->new(
    method    => 'GET',
    target    => '/early',
    scheme    => 'https',
    authority => 'localhost',
);

my $early_client_tx = $second_client_h3->request(
    $early_request,
    early_data  => 1,
    datagrams   => 1,
    stream_body => 1,
);

ok($early_client_tx->early_data,
    'client Transaction records that request was sent in 0-RTT');

my $second_server_quic;
ok(
    run_until(sub {
        $second_server_quic ||= $server_driver->next_connection;
        return defined $second_server_quic;
    }),
    'server accepts the returning QUIC connection',
);

my $early_datagram_policy_calls = 0;
my $second_server_h3 = h3_server(
    $second_server_quic,
    remembered_local_settings => $remembered_local,
    datagram_request => sub {
        my ($connection, $request) = @_;
        ++$early_datagram_policy_calls;
        return $request->target eq '/early' ? 1 : 0;
    },
);
$second_server_h3->start;

is(
    $second_server_h3->next_transaction,
    undef,
    'server does not expose a 0-RTT request before handshake acceptance',
);
is(
    $early_datagram_policy_calls,
    0,
    'server does not invoke application Datagram policy before handshake acceptance',
);

ok(
    $early_client_tx->send_datagram('early-http-datagram'),
    'client sends an HTTP Datagram using remembered HTTP/3 and QUIC state',
);

$early_client_tx->request_body->complete;

my $early_server_tx;
ok(
    run_until(sub {
        $early_server_tx ||= $second_server_h3->next_transaction;

        return defined($early_server_tx)
            && $second_quic->ready
            && $second_server_quic->ready
            && $second_quic->early_data_status eq 'accepted'
            && $second_client_h3->peer_settings_received;
    }),
    'accepted 0-RTT request becomes application-visible after the handshake',
);

is(
    $early_datagram_policy_calls,
    1,
    'server invokes application Datagram policy once after handshake acceptance',
);

ok($early_server_tx->early_data,
    'server Transaction retains the request early-data origin');
is($early_server_tx->request->target, '/early',
    'server receives the replay-safe early request');

ok(!$second_client_h3->failed,
    'current server SETTINGS validate against remembered 0-RTT state');
ok(!$second_client_h3->using_remembered_peer_settings,
    'current SETTINGS replace the remembered initial view');

my $early_datagram = $early_server_tx->next_datagram;
is(
    $early_datagram,
    'early-http-datagram',
    'buffered 0-RTT HTTP Datagram is delivered only after handshake acceptance',
);

$early_server_tx->response->status(204);
$early_server_tx->respond($early_server_tx->response);

ok(
    run_until(sub {
        return $early_client_tx->is_complete
            && $early_server_tx->is_complete;
    }),
    'accepted 0-RTT request completes normally',
);
is($early_client_tx->response->status, 204,
    'accepted early request receives its response');

my $third = new_client(early_data => $quic_early);
my $third_quic = $third->{driver}->connection;
my $third_client_h3 = h3_client(
    $third_quic,
    remembered_peer_settings => $remembered_peer,
);
$third_client_h3->start;

my $replayed_request = Uniform::HTTP::Request->new(
    method    => 'GET',
    target    => '/replayed',
    scheme    => 'https',
    authority => 'localhost',
);

my $replayed_tx = $third_client_h3->request(
    $replayed_request,
    early_data => 1,
);
ok($replayed_tx->early_data,
    'replayed attempt initially creates an early HTTP/3 Transaction');

my $third_server_quic;
ok(
    run_until(sub {
        $third_server_quic ||= $server_driver->next_connection;
        return defined($third_server_quic)
            && $third_quic->ready
            && $third_server_quic->ready
            && $third_quic->early_data_status eq 'rejected';
    }),
    'QUIC rejects replayed 0-RTT and completes the fallback handshake',
);

ok(
    run_until(sub {
        my $status = $third_client_h3->early_data_status;
        return $third_client_h3->started
            && $status eq 'rejected'
            && $replayed_tx->is_terminal;
    }),
    'HTTP/3 rolls back rejected early streams and restarts for 1-RTT',
);

is($replayed_tx->state, 'error',
    'rejected early Transaction is reported as an error');
like($replayed_tx->error, qr/0-RTT was rejected/,
    'rejected early Transaction explains that replay-safe retry is required');

my $third_server_h3 = h3_server($third_server_quic);
$third_server_h3->start;

my $retry_request = Uniform::HTTP::Request->new(
    method    => 'GET',
    target    => '/retry',
    scheme    => 'https',
    authority => 'localhost',
);

my $retry_tx = $third_client_h3->request($retry_request);
ok(!$retry_tx->early_data,
    'replacement request uses ordinary 1-RTT');

my $retry_server_tx;
ok(
    run_until(sub {
        $retry_server_tx ||= $third_server_h3->next_transaction;
        return defined $retry_server_tx;
    }),
    'server receives replacement request after early-data rollback',
);

is($retry_server_tx->request->target, '/retry',
    'replacement request is cleanly decoded after rollback');

$retry_server_tx->response->status(204);
$retry_server_tx->respond($retry_server_tx->response);

ok(
    run_until(sub {
        return $retry_tx->is_complete
            && $retry_server_tx->is_complete;
    }),
    'replacement 1-RTT request completes successfully',
);

done_testing;
