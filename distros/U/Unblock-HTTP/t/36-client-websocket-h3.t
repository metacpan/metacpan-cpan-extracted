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
use Unblock::HTTP::Client;

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
my (@deferred, @server_messages, @ordinary, @releases);
my ($server_ws, $server_tx, $server_h3);
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
    my @now = splice @deferred;
    $_->() for @now;
    my $wait = 0.02;
    $now = time();
    for my $deadline ($server_deadline, $client_deadline) {
        next unless defined $deadline;
        my $remain = $deadline - $now;
        $remain = 0 if $remain < 0;
        $wait = $remain if $remain < $wait;
    }
    for my $socket ($select->can_read($wait)) {
        my $bytes = '';
        my $peer = recv($socket, $bytes, 65535, 0);
        die "UDP recv failed: $!" unless defined $peer;
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
    my $deadline = time() + 10;
    while (time() < $deadline) {
        return 1 if $condition->();
        tick();
    }
    return $condition->() ? 1 : 0;
}

my ($ready_factory, @client_messages, @opened, @finished, @errors);
my $connect_count = 0;
my $client = Unblock::HTTP::Client->new(
    http3 => { websocket => 1 },
    max_connections_per_origin => 1,
    connect_quic => sub {
        my ($origin, $ready) = @_;
        ++$connect_count;
        $ready_factory = $ready;
    },
    defer => $defer,
    release_connection => sub { push @releases, [@_] },
);
my $first = $client->connect_websocket(
    url => 'wss://localhost/chat', http_version => '3',
    backend => 'perl',
    on_open => sub {
        my ($ws, $tx) = @_;
        push @opened, $tx;
        $ws->send_text('hello-h3');
    },
    on_message => sub { push @client_messages, $_[1] },
    on_finish => sub { push @finished, $_[0]->state },
    on_error => sub { push @errors, $_[1] },
);
is($first->state, 'connecting', 'H3 WebSocket connects through QUIC factory');
ok(!$first->transaction, 'no request stream before QUIC and H3 SETTINGS');
is($connect_count, 1, 'one QUIC connection attempt');

$server_driver->start;
$client_driver->start;
my $server_quic;
ok(run_until(sub {
    $server_quic ||= $server_driver->next_connection;
    $server_quic && $server_quic->ready && $client_quic->ready;
}), 'actual QUIC/TLS connection established');
$server_h3 = $definition->attach_quic(connection => $server_quic);
$ready_factory->(connection => $client_quic, verified_origin => 1);
is($first->state, 'queued', 'H3 WebSocket waits for server SETTINGS');
ok(!$first->transaction, 'Extended CONNECT not submitted before SETTINGS');
is($connect_count, 1, 'no repeated connection while awaiting SETTINGS');

ok(run_until(sub { $first->websocket && @client_messages >= 2 }),
    'unified H3 Client exchanges WebSocket frames over QUIC/TLS');
isa_ok($first->transaction, 'Unblock::HTTP3::Transaction');
isa_ok($first->websocket, 'Unblock::WebSocket::Client');
is($first->state, 'active', 'H3 stream remains active after HTTP 200');
is(scalar @opened, 1, 'on_open called exactly once');
is_deeply(\@client_messages, ['welcome-h3', 'echo:hello-h3'],
    'incoming WebSocket frames retain order on H3 stream');
is_deeply(\@server_messages, [['hello-h3', 'text']],
    'server receives one outgoing WebSocket frame');
is($client->pool_stats->{connections}, 1, 'QUIC connection remains in pool');
is($client->pool_stats->{active}, 1, 'WebSocket occupies one QUIC stream');
is($connect_count, 1, 'initial WebSocket did not open a second QUIC connection');

my @second_messages;
my $second = $client->connect_websocket(
    url => 'wss://localhost/second',
    backend => 'perl',
    on_message => sub { push @second_messages, $_[1] },
);
ok(run_until(sub { $second->websocket }), 'H3-only policy defaults to version 3');
$second->websocket->send_text('second-h3');
ok(run_until(sub { @second_messages >= 2 }),
    'second H3 WebSocket receives greeting and reply');
is_deeply(\@second_messages, ['welcome-h3', 'echo:second-h3'],
    'independent H3 WebSocket stream works');
is($client->pool_stats->{active}, 2, 'two H3 WebSockets share one QUIC connection');
is($connect_count, 1, 'multiplexed H3 WebSockets reuse QUIC');

my ($ordinary_status, $ordinary_body);
my $ordinary = $client->request(
    url => 'https://localhost/ordinary', http_version => '3',
    on_response => sub {
        my ($tx, $response) = @_;
        $ordinary_status = $response->status;
        $ordinary_body = $response->body;
    },
);
ok(run_until(sub { $ordinary->is_terminal }),
    'normal HTTP3 request completes alongside two WebSockets');
is($ordinary_status, 200, 'ordinary H3 request succeeds');
is($ordinary_body, 'ordinary-ok', 'ordinary H3 response is unchanged');
is_deeply(\@ordinary, ['/ordinary'], 'ordinary request bypasses WebSocket handler');

my (@denied_error, @denied_finish);
my $denied = $client->connect_websocket(
    url => 'wss://localhost/deny', http_version => '3',
    on_open => sub { die 'denied WebSocket must not open' },
    on_error => sub { push @denied_error, $_[1] },
    on_finish => sub { push @denied_finish, $_[0]->state },
);
ok(run_until(sub { $denied->is_terminal }),
    'HTTP3 rejected WebSocket terminates the operation');
is($denied->state, 'error', 'HTTP 403 WebSocket handshake is an error');
ok(!$denied->websocket, 'rejected H3 handshake creates no WebSocket');
is(scalar @denied_error, 1, 'rejected H3 handshake invokes on_error once');
is_deeply(\@denied_finish, ['cancelled'],
    'underlying H3 stream finishes once with native cancelled state');
is($client->pool_stats->{active}, 2,
    'denied H3 stream returns credit without affecting two WebSockets');

$second->cancel;
ok(run_until(sub { $second->is_terminal }),
    'one H3 WebSocket can be cancelled independently');
is($second->state, 'cancelled', 'cancelled WebSocket reports cancelled state');
is($client->pool_stats->{active}, 1, 'cancel returns only the chosen stream credit');
$first->websocket->send_text('still-open');
ok(run_until(sub { @client_messages >= 3 }),
    'other WebSocket still works after sibling cancellation');
is($client_messages[2], 'echo:still-open', 'active WebSocket retains its stream');

my $released_before = scalar @releases;
$client->shutdown;
is(scalar @releases, $released_before,
    'shutdown does not release QUIC with active WebSocket stream');
is($first->state, 'active', 'active WebSocket survives Client shutdown');
$first->websocket->close;
ok(run_until(sub { $first->is_terminal }),
    'H3 Client WebSocket Close ends its QUIC stream');
is($first->state, 'complete', 'graceful H3 WebSocket finishes successfully');
is_deeply(\@finished, ['complete'], 'H3 on_finish invoked once');
is_deeply(\@errors, [], 'no WebSocket stream errors');
is(scalar @releases, $released_before + 1,
    'retired QUIC connection released after last stream finishes');

done_testing;
