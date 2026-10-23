use strict;
use warnings;
use Test::More;
use IO::Select;
use IO::Socket::INET;
use File::Temp qw(tempdir);
use Time::HiRes qw(time);

BEGIN {
    eval {
        require Net::QUIC::Driver;
        require Unblock::HTTP3::Client;
        require Unblock::WebSocket::Client;
        require Unblock::WebSocket::Handshake;
        1;
    } or plan skip_all => 'Net::QUIC, HTTP3 and WebSocket are required';
}
use Unblock::HTTP::Server;
use Unblock::HTTP::_WebSocketH2Body;

my $dir = tempdir(CLEANUP => 1);
my ($cert, $key) = ("$dir/cert.pem", "$dir/key.pem");
my $cert_ok = system(
    'openssl', 'req', '-x509', '-newkey', 'rsa:2048', '-nodes',
    '-days', '1', '-subj', '/CN=localhost',
    '-addext', 'subjectAltName=DNS:localhost,IP:127.0.0.1',
    '-keyout', $key, '-out', $cert,
);
if ($cert_ok != 0) {
    plan skip_all => 'openssl executable is required for QUIC loopback TLS';
}

sub udp {
    my $socket = IO::Socket::INET->new(
        LocalAddr => '127.0.0.1', LocalPort => 0, Proto => 'udp',
    );
    die "could not open loopback UDP socket: $!" unless $socket;
    return $socket;
}
sub send_to {
    my ($socket, $datagram) = @_;
    my $bytes = $datagram->data;
    my $sent = send($socket, $bytes, 0, $datagram->peer);
    die "QUIC UDP send failed: $!" unless defined $sent;
    die 'partial QUIC UDP send' if $sent != length($bytes);
    return 1;
}

my ($ss, $cs) = (udp(), udp());
my ($server_deadline, $client_deadline);
my (@deferred, @server_messages, @client_messages, @ordinary);
my ($server_ws, $server_tx, $server_h3, $client_h3, $client_ws, $client_bridge);
my $defer = sub { push @deferred, $_[0] };
my $definition = Unblock::HTTP::Server->new(
    http3 => { websocket => 1 },
    defer => $defer,
    on_request => sub {
        my ($tx, $request) = @_;
        push @ordinary, $request->target;
        $tx->respond(status => 200, body => 'ordinary-ok');
    },
    on_websocket => sub {
        my ($tx, $request) = @_;
        return undef if $request->target eq '/deny';
        return {
            backend => 'perl',
            on_open => sub {
                ($server_ws, $server_tx) = @_[0, 1];
                $server_ws->send_text('welcome-h3');
            },
            on_message => sub {
                my ($ws, $payload, $type) = @_;
                push @server_messages, [$payload, $type];
                $ws->send_text("echo:$payload");
            },
        };
    },
);
my $server_driver = Net::QUIC::Driver->server(
    alpn => 'h3',
    certificate_file => $cert, private_key_file => $key,
    send => sub { send_to($ss, $_[0]) },
    set_timeout => sub {
        $server_deadline = defined($_[0]) ? time() + $_[0] : undef;
    },
);
my $client_driver = Net::QUIC::Driver->client(
    local => getsockname($cs), peer => getsockname($ss),
    alpn => 'h3', server_name => 'localhost', ca_file => $cert,
    send => sub { send_to($cs, $_[0]) },
    set_timeout => sub {
        $client_deadline = defined($_[0]) ? time() + $_[0] : undef;
    },
);
my $client_quic = $client_driver->connection;
my $select = IO::Select->new($ss, $cs);

sub tick {
    my $now = time();
    if (defined($server_deadline) && $server_deadline <= $now) {
        $server_deadline = undef;
        $server_driver->timeout;
    }
    if (defined($client_deadline) && $client_deadline <= $now) {
        $client_deadline = undef;
        $client_driver->timeout;
    }
    my @ready = splice @deferred;
    $_->() for @ready;

    my $wait = 0.03;
    $now = time();
    for my $deadline ($server_deadline, $client_deadline) {
        next unless defined $deadline;
        my $left = $deadline - $now;
        $left = 0 if $left < 0;
        $wait = $left if $left < $wait;
    }
    for my $socket ($select->can_read($wait)) {
        my $bytes = '';
        my $peer = recv($socket, $bytes, 65535, 0);
        die "QUIC UDP recv failed: $!" unless defined $peer;
        my $local = getsockname($socket);
        if (fileno($socket) == fileno($ss)) {
            $server_driver->receive($bytes, $local, $peer);
        } else {
            $client_driver->receive($bytes, $local, $peer);
        }
    }
}
sub run_until {
    my ($condition) = @_;
    my $end = time() + 10;
    while (time() < $end) {
        return 1 if $condition->();
        tick();
    }
    return $condition->() ? 1 : 0;
}

$server_driver->start;
$client_driver->start;
my $server_quic;
ok(run_until(sub {
    $server_quic ||= $server_driver->next_connection;
    $server_quic && $server_quic->ready && $client_quic->ready;
}), 'real QUIC/TLS h3 handshake completes');

$server_h3 = $definition->attach_quic(connection => $server_quic);
$client_h3 = Unblock::HTTP3::Client->new(quic => $client_quic);
$client_h3->start;
ok(run_until(sub {
    $server_h3->peer_settings_received && $client_h3->peer_settings_received;
}), 'both HTTP3 endpoints receive initial SETTINGS');
ok($server_h3->extended_connect_enabled,
    'unified Server advertises H3 Extended CONNECT');
ok($client_h3->peer_extended_connect_enabled,
    'peer observes H3 Extended CONNECT capability');

my ($handshake, $request) =
    Unblock::WebSocket::Handshake->client_request(
        'wss://localhost/chat', http_version => '3',
    );
my (@errors, @completed, $client_tx);
$client_tx = $client_h3->request(
    $request,
    stream_body => 1,
    on_response => sub {
        my ($tx, $response) = @_;
        $handshake->validate_client_response($response);
        $client_bridge = Unblock::HTTP::_WebSocketH2Body->new(
            transaction => $tx, defer => $defer,
        );
        $client_ws = Unblock::WebSocket::Client->new(
            backend => 'perl', transport => $client_bridge,
            on_message => sub { push @client_messages, $_[1] },
        );
        $client_bridge->websocket($client_ws);
        $client_ws->send_text('hello-h3');
    },
    on_data => sub {
        die 'received WebSocket frame before successful H3 handshake'
            unless $client_ws;
        $client_ws->input($_[1]);
    },
    on_drain => sub { $client_bridge->resume if $client_bridge },
    on_finish => sub { push @completed, $_[0]->state },
    on_error => sub { push @errors, $_[1] },
);
ok($client_tx, 'H3 Extended CONNECT created a real QUIC request stream');
ok(run_until(sub { @client_messages >= 2 }),
    'WebSocket greeting and echo cross real QUIC socket');
is_deeply(\@client_messages, ['welcome-h3', 'echo:hello-h3'],
    'real HTTP3 DATA transports bidirectional WebSocket frames');
is_deeply(\@server_messages, [['hello-h3', 'text']],
    'H3 WebSocket Server receives client payload once');
isa_ok($server_tx, 'Unblock::HTTP3::Transaction');
ok(!$client_tx->is_terminal, 'WebSocket H3 request remains streaming');
is_deeply(\@ordinary, [], 'WebSocket Extended CONNECT bypasses ordinary handler');

my $ordinary_response;
$client_h3->request(
    method => 'GET', target => '/normal', scheme => 'https',
    authority => 'localhost',
    on_response => sub { $ordinary_response = $_[1]->status },
);
ok(run_until(sub { defined $ordinary_response }),
    'ordinary H3 transaction runs alongside WebSocket');
is($ordinary_response, 200, 'ordinary H3 response remains functional');
is_deeply(\@ordinary, ['/normal'], 'only GET reached ordinary HTTP handler');

# Denied and malformed H3 WebSocket attempts are rejected per stream,
# without terminating another WebSocket or the shared QUIC connection.
my ($deny_handshake, $deny_request) =
    Unblock::WebSocket::Handshake->client_request(
        'wss://localhost/deny', http_version => '3',
    );
my $deny_status;
$client_h3->request($deny_request,
    stream_body => 1,
    on_response => sub { $deny_status = $_[1]->status },
);
ok(run_until(sub { defined $deny_status }),
    'denied H3 WebSocket gets a final response');
is($deny_status, 403, 'application denial returns HTTP 403');

require Uniform::HTTP::Request;
my $bad_request = Uniform::HTTP::Request->new(
    method => 'CONNECT', protocol => 'websocket',
    target => '/invalid', scheme => 'https', authority => 'localhost',
    version => '3',
    headers => [['Sec-WebSocket-Version' => '12']],
);
my $bad_status;
$client_h3->request($bad_request,
    stream_body => 1,
    on_response => sub { $bad_status = $_[1]->status },
);
ok(run_until(sub { defined $bad_status }),
    'malformed H3 WebSocket gets a final response');
is($bad_status, 400, 'malformed H3 handshake returns HTTP 400');
ok(!$client_tx->is_terminal, 'invalid sibling streams do not close active WebSocket');

$client_ws->close;
ok(run_until(sub { $client_ws->close_received }),
    'WebSocket Close response arrives over H3 DATA');
ok($server_ws->close_received, 'server received WebSocket Close');
ok(run_until(sub { $client_tx->is_terminal }),
    'client H3 transaction terminates after WebSocket Close');
is_deeply(\@errors, [], 'real QUIC WebSocket exchange has no stream errors');
is_deeply(\@completed, ['complete'], 'client H3 Transaction completes once');

done_testing;
