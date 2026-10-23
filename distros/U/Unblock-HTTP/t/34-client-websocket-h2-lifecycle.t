use strict;
use warnings;
use Test::More;

BEGIN {
    eval {
        require Unblock::HTTP2::Client;
        require Unblock::HTTP2::Server;
        require Unblock::WebSocket::Client;
        1;
    } or plan skip_all => 'HTTP2 and WebSocket engines are required';
}
use Unblock::HTTP::Client;
use Unblock::HTTP::Server;

{
    package Local::LifeHost;
    sub new { bless { output => '', aborts => [] }, shift }
    sub unblock_send { $_[0]{output} .= $_[1]; return 1 }
    sub unblock_finish { ++$_[0]{finished}; return }
    sub unblock_abort { push @{ $_[0]{aborts} }, $_[1]; return }
    sub take {
        my ($self) = @_;
        my $bytes = $self->{output};
        $self->{output} = '';
        return $bytes;
    }
}

my (@later, @pairs, @releases);
sub pump {
    for (1 .. 200) {
        my $moved = 0;
        for my $pair (@pairs) {
            my ($ch, $sh, $server) = @$pair;
            my $request = $ch->take;
            if (length $request) { $server->input($request); ++$moved }
            my $response = $sh->take;
            if (length $response) { $ch->{engine}->input($response); ++$moved }
        }
        my @batch = splice @later;
        $_->() for @batch;
        $moved += @batch;
        return if !$moved;
    }
    die 'HTTP2 WebSocket lifecycle pump did not settle';
}
sub make_client {
    my ($definition) = @_;
    return Unblock::HTTP::Client->new(
        http2 => { websocket => 1 },
        max_connections_per_origin => 1,
        defer => sub { push @later, $_[0] },
        release_connection => sub { push @releases, [@_] },
        connect_stream => sub {
            my ($origin, $alpn, $ready) = @_;
            my $ch = Local::LifeHost->new;
            my $sh = Local::LifeHost->new;
            my $server = ref($definition) eq 'CODE'
                ? $definition->($sh)
                : $definition->attach_stream(transport => $sh, protocol => 'h2');
            push @pairs, [$ch, $sh, $server];
            $ch->{engine} = $ready->(transport => $ch, alpn => 'h2');
        },
    );
}

# An application denial must fail just the CONNECT transaction. This is
# NOT a successful WebSocket and must not fire on_open.
my $deny_server = Unblock::HTTP::Server->new(
    http2 => { websocket => 1 },
    defer => sub { push @later, $_[0] },
    on_request => sub { die 'denied WebSocket routed to ordinary HTTP' },
    on_websocket => sub { return undef },
);
my $deny_client = make_client($deny_server);
my (@deny_errors, @deny_finish);
my $denied = $deny_client->connect_websocket(
    url => 'wss://example.test/denied', http_version => '2',
    on_open => sub { die 'denied WebSocket must not open' },
    on_error => sub { push @deny_errors, $_[1] },
    on_finish => sub { push @deny_finish, $_[0]->state },
);
pump();
is($denied->state, 'error', 'HTTP 403 rejects H2 WebSocket client operation');
ok(!$denied->websocket, 'rejected CONNECT creates no WebSocket');
is(scalar @deny_errors, 1, 'HTTP 403 reports one handshake error');
is_deeply(\@deny_finish, ['error'], 'HTTP 403 terminates once');
is($deny_client->pool_stats->{active}, 0, 'failed handshake releases H2 stream slot');
$deny_client->shutdown;

# A malicious peer must not be able to select an unoffered WebSocket
# subprotocol despite returning HTTP 200.
my $bad_client = make_client(sub {
    my ($host) = @_;
    return Unblock::HTTP2::Server->new(
        transport => $host,
        enable_connect_protocol => 1,
        on_request => sub {
            my ($tx) = @_;
            $tx->respond(
                status => 200,
                headers => [['Sec-WebSocket-Protocol' => 'not-offered']],
                stream_body => 1,
            );
        },
    );
});
my (@bad_errors, @bad_finish);
my $bad = $bad_client->connect_websocket(
    url => 'wss://example.test/invalid', http_version => '2',
    on_open => sub { die 'invalid handshake must not open' },
    on_error => sub { push @bad_errors, $_[1] },
    on_finish => sub { push @bad_finish, $_[0]->state },
);
pump();
is($bad->state, 'error', 'invalid HTTP 200 handshake is rejected');
ok(!$bad->websocket, 'invalid HTTP 200 creates no WebSocket');
is(scalar @bad_errors, 1, 'invalid handshake reports one error');
is_deeply(\@bad_finish, ['error'], 'invalid handshake finishes once');
$bad_client->shutdown;

my ($server_tx, @received, @live_finish, @live_error);
my $life_server = Unblock::HTTP::Server->new(
    http2 => { websocket => 1 },
    defer => sub { push @later, $_[0] },
    on_request => sub {
        my ($tx) = @_;
        $tx->respond(status => 200, body => 'ordinary-ok');
    },
    on_websocket => sub {
        my ($tx) = @_;
        return {
            backend => 'perl',
            on_open => sub { $server_tx = $_[1] },
            on_message => sub { $_[0]->send_text('echo:'.$_[1]) },
        };
    },
);
my $life_client = make_client($life_server);
my $live = $life_client->connect_websocket(
    url => 'wss://example.test/live', http_version => '2',
    backend => 'perl',
    on_message => sub { push @received, $_[1] },
    on_finish => sub { push @live_finish, $_[0]->state },
    on_error => sub { push @live_error, $_[1] },
);
pump();
isa_ok($live->websocket, 'Unblock::WebSocket::Client');
is($life_client->pool_stats->{active}, 1, 'accepted WebSocket occupies one H2 stream');
my $before_shutdown = scalar @releases;
$life_client->shutdown;
is(scalar @releases, $before_shutdown, 'Client shutdown does not close active WebSocket');
is($live->state, 'active', 'WebSocket remains active through shutdown');
$live->websocket->send_text('after-shutdown');
pump();
is_deeply(\@received, ['echo:after-shutdown'], 'WebSocket remains writable after shutdown');
$live->websocket->close;
pump();
is($live->state, 'complete', 'stream completes after graceful WebSocket Close');
is_deeply(\@live_finish, ['complete'], 'terminal observer called once after Close');
is(scalar @live_error, 0, 'graceful shutdown does not invoke on_error');
is(scalar @releases, $before_shutdown + 1, 'retired H2 connection released once after last stream');

# A remote stream RESET should fail only that WebSocket, without
# corrupting its multiplexed connection or being mistaken for Close.
my ($reset_tx, @reset_finished, @reset_errors);
my $reset_server = Unblock::HTTP::Server->new(
    http2 => { websocket => 1 },
    defer => sub { push @later, $_[0] },
    on_request => sub {
        my ($tx) = @_;
        $tx->respond(status => 200, body => 'still-usable');
    },
    on_websocket => sub {
        return {
            backend => 'perl',
            on_open => sub { $reset_tx = $_[1] },
        };
    },
);
my $reset_client = make_client($reset_server);
my $reset = $reset_client->connect_websocket(
    url => 'wss://example.test/reset', http_version => '2',
    backend => 'perl',
    on_finish => sub { push @reset_finished, $_[0]->state },
    on_error => sub { push @reset_errors, $_[1] },
);
pump();
isa_ok($reset->websocket, 'Unblock::WebSocket::Client');
$reset_tx->reset(8);
pump();
is($reset->state, 'error', 'remote RESET is a stream error, not a graceful Close');
is_deeply(\@reset_finished, ['error'], 'remote RESET finishes operation once');
is(scalar @reset_errors, 1, 'remote RESET reports one stream error');
is($reset_client->pool_stats->{active}, 0, 'reset returns only stream credit');
my $after_reset = '';
$reset_client->request(
    url => 'https://example.test/ordinary',
    http_version => '2',
    on_data => sub { $after_reset .= $_[1] },
);
pump();
is($after_reset, 'still-usable', 'shared H2 connection survives remote RESET');
$reset_client->shutdown;

done_testing;
