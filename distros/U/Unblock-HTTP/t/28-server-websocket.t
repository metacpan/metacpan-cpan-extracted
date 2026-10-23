use strict;
use warnings;
use Test::More;
use Scalar::Util qw(refaddr weaken);
use Unblock::HTTP::Server;

BEGIN {
    eval {
        require Unblock::HTTP1::Client;
        require Unblock::WebSocket::Handshake;
        require Unblock::WebSocket::Client;
        require Unblock::WebSocket::Server;
        1;
    } or plan skip_all => 'HTTP1 and Unblock::WebSocket are required';
}

{
    package Local::WebSocketHost;
    sub new { bless { queue => [], upgrades => 0, aborts => [] }, shift }
    sub unblock_send { push @{ $_[0]{queue} }, $_[1]; return 1 }
    sub unblock_finish { ++$_[0]{finished}; return }
    sub unblock_abort { push @{ $_[0]{aborts} }, $_[1]; return }
    sub unblock_upgrade {
        my ($self, $websocket) = @_;
        ++$self->{upgrades};
        $self->{consumer} = $websocket;
    }
    sub take { join '', splice @{ $_[0]{queue} } }
    sub receive { $_[0]{consumer}->input($_[1]) }
}
{
    package Local::OrdinaryHost;
    sub new { bless { queue => [] }, shift }
    sub unblock_send { push @{ $_[0]{queue} }, $_[1]; return 1 }
    sub unblock_finish { }
    sub unblock_abort { }
}

my (@messages, @events, @ordinary, $opened, $switch_tx);
my $definition = Unblock::HTTP::Server->new(
    http1 => { websocket => 1 },
    on_headers => sub { push @events, 'headers' },
    on_request => sub {
        my ($tx, $request) = @_;
        push @ordinary, $request->target;
        $tx->respond(status => 200, body => 'ordinary');
    },
    on_websocket => sub {
        my ($tx, $request) = @_;
        push @events, 'offer';
        return {
            backend => 'perl',
            on_message => sub {
                my ($ws, $payload, $type) = @_;
                push @messages, [$payload, $type];
                $ws->send_text("echo:$payload");
            },
            on_open => sub {
                my ($ws, $same_tx, $same_request) = @_;
                push @events, 'open';
                is(refaddr($same_tx), refaddr($switch_tx),
                    'transition retains original HTTP1 transaction') if $switch_tx;
                $opened = $ws;
                $switch_tx = $same_tx;
                isa_ok($same_request, 'Uniform::HTTP::Request');
            },
        };
    },
);

my $host = Local::WebSocketHost->new;
my $server = $definition->attach_stream(transport => $host);
$host->{consumer} = $server;
my ($handshake, $request) =
    Unblock::WebSocket::Handshake->client_request('ws://example.test/chat');
my $client = Unblock::HTTP1::Client->new;
my (@client_events, @client_messages);
$client->request(
    $request,
    on_response => sub {
        $handshake->validate_client_response($_[1]);
        push @client_events, 'response';
    },
    on_switch => sub { push @client_events, 'switch' },
);
my $websocket_client = Unblock::WebSocket::Client->new(
    backend => 'perl',
    on_message => sub { push @client_messages, $_[1] },
);
$websocket_client->send_text('coalesced');
$server->input($client->output . $websocket_client->output);

ok($server->is_switched, 'original HTTP1 engine switched');
is($host->{upgrades}, 1, 'adapter replaced the incoming consumer once');
isa_ok($host->{consumer}, 'Unblock::WebSocket::Server');
is(refaddr($host->{consumer}), refaddr($opened),
    'application and framework see the same WebSocket instance');
is_deeply(\@events, ['headers', 'offer', 'open'],
    'headers, acceptance and actual opening occur in order');
is_deeply(\@messages, [['coalesced', 'text']],
    'first WebSocket frame coalesced with HTTP request is delivered once');
is_deeply(\@ordinary, [], 'WebSocket upgrade is not dispatched as ordinary HTTP');
is($server->take_remainder, '', 'upgrade tail was transferred exactly once');

my $wire = $host->take;
like($wire, qr/\AHTTP\/1\.1 101\b/, '101 response precedes WebSocket frames');
$client->input($wire);
is_deeply(\@client_events, ['response', 'switch'],
    'client validates handshake before switching');
$websocket_client->input($client->take_remainder);
is_deeply(\@client_messages, ['echo:coalesced'], 'echo arrives over established WebSocket');

$websocket_client->send_text('later');
$host->receive($websocket_client->output);
$websocket_client->input($host->take);
is_deeply(\@messages, [['coalesced', 'text'], ['later', 'text']],
    'later messages are delivered directly to WebSocket, not HTTP');
is_deeply(\@client_messages, ['echo:coalesced', 'echo:later'],
    'attached WebSocket output works after handoff');
is(scalar @{ $host->{aborts} }, 0, 'handoff does not abort the host');

my $ordinary_host = Local::WebSocketHost->new;
my $ordinary_engine = $definition->attach_stream(transport => $ordinary_host);
my $ordinary_client = Unblock::HTTP1::Client->new(receive_body => 'buffered');
my $ordinary_tx = $ordinary_client->request(
    method => 'GET', target => '/ordinary', authority => 'example.test',
);
$ordinary_engine->input($ordinary_client->output);
$ordinary_client->input($ordinary_host->take);
is($ordinary_tx->response->body, 'ordinary', 'normal requests retain original callback');
is_deeply(\@ordinary, ['/ordinary'], 'ordinary handler receives normal HTTP');
is($ordinary_host->{upgrades}, 0, 'normal response does not switch');

my ($invalid_handshake, $invalid_request) =
    Unblock::WebSocket::Handshake->client_request('ws://example.test/bad');
my $invalid_client = Unblock::HTTP1::Client->new;
$invalid_client->request($invalid_request);
my $invalid_wire = $invalid_client->output;
$invalid_wire =~ s/(Sec-WebSocket-Version:\s*)13/$1 12/i
    or die 'could not produce invalid handshake';
my $invalid_host = Local::WebSocketHost->new;
my $invalid_server = $definition->attach_stream(transport => $invalid_host);
$invalid_server->input($invalid_wire);
like($invalid_host->take, qr/\AHTTP\/1\.1 400\b/,
    'invalid upgrade receives HTTP 400, never HTTP 101');
is($invalid_host->{upgrades}, 0, 'invalid handshake never switches transport');

my $denied = Unblock::HTTP::Server->new(
    http1 => { websocket => 1 },
    on_request => sub { die 'must not receive upgrade as ordinary request' },
    on_websocket => sub { return undef },
);
my $denied_host = Local::WebSocketHost->new;
my $denied_server = $denied->attach_stream(transport => $denied_host);
my ($denied_handshake, $denied_request) =
    Unblock::WebSocket::Handshake->client_request('ws://example.test/denied');
my $denied_client = Unblock::HTTP1::Client->new;
$denied_client->request($denied_request);
$denied_server->input($denied_client->output);
like($denied_host->take, qr/\AHTTP\/1\.1 403\b/, 'application may deny an upgrade');
is($denied_host->{upgrades}, 0, 'denial does not change input consumer');

for my $case (
    [ sub { Unblock::HTTP::Server->new(http1 => { websocket => 1 }, on_request => sub {}) },
      qr/on_websocket callback is required/ ],
    [ sub { Unblock::HTTP::Server->new(http2 => { websocket => 1 }, on_request => sub {}) },
      qr/on_websocket callback is required/ ],
    [ sub { Unblock::HTTP::Server->new(http3 => { websocket => 1 }, on_request => sub {}) },
      qr/on_websocket callback is required/ ],
    [ sub { Unblock::HTTP::Server->new(http1 => {}, on_request => sub {}, on_websocket => sub {}) },
      qr/requires an enabled websocket protocol/ ],
    [ sub { $definition->attach_stream(transport => Local::OrdinaryHost->new) },
      qr/unblock_upgrade/ ],
) {
    ok(!eval { $case->[0]->(); 1 }, 'unsafe or incomplete WebSocket option rejected');
    like($@, $case->[1], 'rejection explains missing capability');
}

# Existing Client pool must continue to reject WebSocket enablement.
require Unblock::HTTP::_Policy;
ok(!eval { Unblock::HTTP::_Policy->new(http1 => { websocket => 1 }); 1 },
    'Client-side policy continues to reject unimplemented WebSocket attachment');
like($@, qr/not implemented/, 'unsupported Client mode remains explicit');

done_testing;
