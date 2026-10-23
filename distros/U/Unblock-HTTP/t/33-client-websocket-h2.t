use strict;
use warnings;
use Test::More;
use Scalar::Util qw(refaddr);

BEGIN {
    eval {
        require Unblock::HTTP2::Client;
        require Unblock::HTTP2::Server;
        require Unblock::WebSocket::Client;
        require Unblock::WebSocket::Handshake;
        1;
    } or plan skip_all => 'HTTP2 and WebSocket libraries are required';
}

use Unblock::HTTP::Client;
use Unblock::HTTP::Server;

{
    package Local::H2ClientHost;
    sub new { bless { output => '', abort => [], finish => 0 }, shift }
    sub unblock_send { $_[0]{output} .= $_[1]; return 1 }
    sub unblock_finish { $_[0]{finish}++; return }
    sub unblock_abort { push @{ $_[0]{abort} }, $_[1]; return }
    sub take {
        my ($self) = @_;
        my $out = $self->{output};
        $self->{output} = '';
        return $out;
    }
}

my (@deferred, @connections, @releases, @server_messages,
    @client_messages, @opened, @completed, @ordinary);
my $defer = sub { push @deferred, $_[0] };
my $definition = Unblock::HTTP::Server->new(
    http2 => { websocket => 1 },
    defer => $defer,
    on_request => sub {
        my ($tx, $request) = @_;
        push @ordinary, $request->target;
        $tx->respond(status => 200, body => 'ordinary-ok');
    },
    on_websocket => sub {
        my ($tx, $request) = @_;
        return {
            backend => 'perl',
            on_message => sub {
                my ($ws, $payload, $type) = @_;
                push @server_messages, [$request->target, $payload, $type];
                $ws->send_text("reply:$payload");
            },
        };
    },
);
my $connect_count = 0;
my $client = Unblock::HTTP::Client->new(
    http2 => { websocket => 1 },
    connect_stream => sub {
        my ($origin, $alpn, $ready) = @_;
        $connect_count++;
        is_deeply($alpn, ['h2'], 'strict H2 WebSocket offers only H2 ALPN');
        my $ch = Local::H2ClientHost->new;
        my $sh = Local::H2ClientHost->new;
        my $server = $definition->attach_stream(
            transport => $sh, protocol => 'h2',
        );
        push @connections, [$ch, $sh, $server];
        my $engine = $ready->(transport => $ch, alpn => 'h2');
        $ch->{consumer} = $engine;
    },
    defer => $defer,
    max_connections_per_origin => 1,
    release_connection => sub { push @releases, [@_] },
);

sub pump {
    for (1 .. 200) {
        my $moved = 0;
        for my $pair (@connections) {
            my ($ch, $sh, $server) = @$pair;
            my $request_bytes = $ch->take;
            if (length $request_bytes) {
                $server->input($request_bytes);
                ++$moved;
            }
            my $response_bytes = $sh->take;
            if (length $response_bytes) {
                $ch->{consumer}->input($response_bytes);
                ++$moved;
            }
        }
        my @now = splice @deferred;
        $_->() for @now;
        $moved += scalar @now;
        return unless $moved;
    }
    die 'HTTP2 Client WebSocket pump did not settle';
}

my $first = $client->connect_websocket(
    url => 'wss://example.test/chat',
    http_version => '2',
    backend => 'perl',
    on_open => sub {
        my ($ws, $tx) = @_;
        push @opened, $tx;
        isa_ok($ws, 'Unblock::WebSocket::Client');
        isa_ok($tx, 'Unblock::HTTP2::Transaction');
        $ws->send_text('hello');
    },
    on_message => sub { push @client_messages, $_[1] },
    on_finish => sub { push @completed, $_[0]->state },
);
ok(!$first->websocket, 'no WebSocket available before peer SETTINGS');
is($first->state, 'queued', 'Extended CONNECT remains queued until SETTINGS');
is($first->transaction, undef, 'no premature H2 CONNECT transaction');
is($connect_count, 1, 'one connection established while waiting for SETTINGS');
pump();
isa_ok($first->websocket, 'Unblock::WebSocket::Client');
is($first->state, 'active', 'WebSocket H2 stream stays active after handshake');
ok(!$first->transaction->is_terminal, 'H2 transaction remains streaming');
is_deeply(\@server_messages, [['/chat', 'hello', 'text']],
    'on_open frames reach server through deferred H2 DATA');
is_deeply(\@client_messages, ['reply:hello'],
    'server response returns through H2 DATA stream');
is($client->pool_stats->{connections}, 1, 'H2 connection stays in HTTP pool');
is($client->pool_stats->{active}, 1, 'WebSocket occupies one H2 stream slot');
is(scalar @releases, 0, 'WebSocket never releases shared H2 socket');

my $second = $client->connect_websocket(
    url => 'wss://example.test/second', http_version => '2',
    backend => 'perl', on_message => sub { push @client_messages, "second:$_[1]" },
);
pump();
isa_ok($second->websocket, 'Unblock::WebSocket::Client');
is($connect_count, 1, 'second H2 WebSocket multiplexes over same connection');
is($client->pool_stats->{active}, 2, 'two independent WebSocket H2 streams');
$second->websocket->send_text('two');
pump();
is_deeply(\@server_messages,
    [['/chat', 'hello', 'text'], ['/second', 'two', 'text']],
    'both WebSockets have independent stream data');
is_deeply(\@client_messages, ['reply:hello', 'second:reply:two'],
    'H2 stream responses remain isolated');

my $ordinary_body = '';
$client->request(
    url => 'https://example.test/ordinary', http_version => '2',
    on_data => sub { $ordinary_body .= $_[1] },
);
pump();
is($ordinary_body, 'ordinary-ok', 'ordinary request works beside WebSockets');
is_deeply(\@ordinary, ['/ordinary'], 'only ordinary request reached HTTP callback');
is($connect_count, 1, 'ordinary request shares same underlying H2 connection');

$second->cancel;
pump();
is($second->state, 'cancelled', 'one WebSocket H2 operation can be cancelled');
is($client->pool_stats->{active}, 1, 'cancel frees only the selected H2 slot');
ok(!$first->transaction->is_terminal, 'other WebSocket stream remains active');
$first->websocket->send_text('still-open');
pump();
is_deeply(\@client_messages,
    ['reply:hello', 'second:reply:two', 'reply:still-open'],
    'sibling cancellation does not interrupt live WebSocket');

$first->websocket->close;
pump();
ok($first->is_terminal, 'WebSocket Close allows H2 transaction to terminate');
is_deeply(\@completed, ['complete'], 'H2 on_finish runs after stream terminates');
is($client->pool_stats->{active}, 0, 'closing WebSocket returns H2 stream credit');
is($client->pool_stats->{connections}, 1, 'H2 transport remains pooled');
is(scalar @releases, 0, 'no socket release during stream termination');

$client->shutdown;
is(scalar @releases, 1, 'idle H2 socket released once at shutdown');

# A peer that does not advertise SETTINGS_ENABLE_CONNECT_PROTOCOL rejects the
# queued operation once its SETTINGS frame arrives, without issuing CONNECT.
my (@denied_deferred, @denied_pair, @denied_errors, @denied_finish);
my $no_ws_server = Unblock::HTTP::Server->new(
    http2 => {},
    on_request => sub { die 'unsupported WebSocket must not be dispatched' },
);
my $denied_client = Unblock::HTTP::Client->new(
    http2 => { websocket => 1 },
    defer => sub { push @denied_deferred, $_[0] },
    connect_stream => sub {
        my ($origin, $alpn, $ready) = @_;
        my $ch = Local::H2ClientHost->new;
        my $sh = Local::H2ClientHost->new;
        my $server = $no_ws_server->attach_stream(transport => $sh, protocol => 'h2');
        push @denied_pair, [$ch, $sh, $server];
        $ch->{consumer} = $ready->(transport => $ch, alpn => 'h2');
    },
    max_connections_per_origin => 1,
);
my $denied = $denied_client->connect_websocket(
    url => 'wss://example.test/unsupported',
    http_version => '2',
    on_open => sub { die 'unsupported peer must not open WebSocket' },
    on_error => sub { push @denied_errors, $_[1] },
    on_finish => sub { push @denied_finish, $_[0]->state },
);
is($denied->state, 'queued', 'unsupported peer starts as queued, not dispatched');
for (1 .. 40) {
    my $moved = 0;
    for my $pair (@denied_pair) {
        my ($ch, $sh, $server) = @$pair;
        my $a = $ch->take;
        if (length $a) { $server->input($a); ++$moved }
        my $b = $sh->take;
        if (length $b) { $ch->{consumer}->input($b); ++$moved }
    }
    my @now = splice @denied_deferred;
    $_->() for @now;
    $moved += @now;
    last unless $moved;
}
is($denied->state, 'error', 'peer without Extended CONNECT fails operation');
like($denied->error, qr/peer has not enabled/, 'peer capability rejection is explicit');
is(scalar @denied_errors, 1, 'rejected H2 WebSocket invokes on_error once');
is_deeply(\@denied_finish, ['error'], 'rejected H2 WebSocket finishes once');
ok(!$denied->transaction, 'peer rejection creates no HTTP transaction');

# Cancellation while waiting for peer SETTINGS must not dispatch or replay.
my (@cancel_deferred, $cancel_engine, $cancel_server, $cancel_host);
my $pending_client = Unblock::HTTP::Client->new(
    http2 => { websocket => 1 },
    defer => sub { push @cancel_deferred, $_[0] },
    connect_stream => sub {
        my ($origin, $alpn, $ready) = @_;
        $cancel_host = Local::H2ClientHost->new;
        $cancel_server = Local::H2ClientHost->new;
        $cancel_engine = $no_ws_server->attach_stream(transport => $cancel_server, protocol => 'h2');
        $cancel_host->{consumer} = $ready->(transport => $cancel_host, alpn => 'h2');
    },
);
my $pending = $pending_client->connect_websocket(
    url => 'wss://example.test/cancel', http_version => '2',
    on_error => sub { die 'intentional cancellation is not an error' },
);
is($pending->state, 'queued', 'pending H2 request waits for SETTINGS');
ok($pending->cancel, 'waiting operation can be cancelled');
is($pending->state, 'cancelled', 'cancel changes pending state');
ok(!$pending->transaction, 'cancel before SETTINGS created no transaction');
is($pending_client->pending_count, 0, 'cancel removes pending operation');

done_testing;
