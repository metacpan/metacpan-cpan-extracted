use strict;
use warnings;
use Test::More;

BEGIN {
    eval {
        require Unblock::HTTP2::Client;
        require Unblock::HTTP2::Server;
        require Unblock::WebSocket::Handshake;
        require Unblock::WebSocket::Client;
        1;
    } or plan skip_all => 'real HTTP2 and WebSocket engines are required';
}
use Unblock::HTTP::Server;
use Unblock::WebSocket::Handshake;
use Unblock::WebSocket::Client;

{
    package Local::H2Host;
    sub new { bless { output => '', aborted => [] }, shift }
    sub unblock_send { $_[0]{output} .= $_[1]; return 1 }
    sub unblock_finish { ++$_[0]{finished}; return }
    sub unblock_abort { push @{ $_[0]{aborted} }, $_[1]; return }
    sub take {
        my $self = shift;
        my $bytes = $self->{output};
        $self->{output} = '';
        return $bytes;
    }
}

my (@deferred, @server_events, @messages, @ordinary, @errors);
my ($server_ws, $server_tx);
my $definition = Unblock::HTTP::Server->new(
    http2 => { websocket => 1 },
    defer => sub { push @deferred, $_[0] },
    on_request => sub {
        my ($tx, $request) = @_;
        push @ordinary, $request->target;
        $tx->respond(status => 200, body => 'ordinary-ok');
    },
    on_websocket => sub {
        my ($tx, $request) = @_;
        push @server_events, 'offer:' . $request->target;
        return if $request->target eq '/deny';
        return {
            backend => 'perl',
            on_message => sub {
                my ($ws, $payload, $type) = @_;
                push @messages, [$payload, $type];
                $ws->send_text("echo:$payload");
            },
            on_open => sub {
                my ($ws, $tx, $req) = @_;
                push @server_events, 'open:' . $req->target;
                $server_ws = $ws;
                $server_tx = $tx;
                $ws->send_text('welcome');
            },
        };
    },
);
my $host = Local::H2Host->new;
my $h2server = $definition->attach_stream(
    transport => $host, protocol => 'h2',
);
isa_ok($h2server, 'Unblock::HTTP2::Server');
my $h2client = Unblock::HTTP2::Client->new;

sub pump {
    for (1 .. 150) {
        my $moved = 0;
        my $wire = $h2client->output;
        if (length $wire) {
            $h2server->input($wire);
            $moved++;
        }
        $wire = $host->take;
        if (length $wire) {
            $h2client->input($wire);
            $moved++;
        }
        my @now = splice @deferred;
        for my $cb (@now) {
            $cb->();
            $moved++;
        }
        last unless $moved;
        die 'H2 WebSocket pump did not settle' if $_ == 150;
    }
}

pump();
is($h2client->peer_setting('enable_connect_protocol'), 1,
    'enabled server advertises HTTP2 Extended CONNECT');

my ($client_handshake, $request) =
    Unblock::WebSocket::Handshake->client_request(
        'wss://example.test/chat', http_version => '2',
    );
my (@client_messages, $client_ws);
my $ws_tx = $h2client->request(
    $request,
    stream_body => 1,
    on_response => sub {
        $client_handshake->validate_client_response($_[1]);
        $client_ws = Unblock::WebSocket::Client->new(
            backend => 'perl',
            on_message => sub { push @client_messages, $_[1] },
        );
    },
    on_data => sub {
        die 'WebSocket DATA arrived before successful HTTP2 response'
            unless $client_ws;
        $client_ws->input($_[1]);
    },
    on_error => sub { push @errors, "client:$_[1]" },
);
pump();
isa_ok($server_ws, 'Unblock::WebSocket::Server');
isa_ok($server_tx, 'Unblock::HTTP2::Transaction');
isa_ok($client_ws, 'Unblock::WebSocket::Client');
is_deeply(\@server_events, ['offer:/chat', 'open:/chat'],
    'WebSocket accepted and opened once');
is_deeply(\@client_messages, ['welcome'],
    'on_open output flushed through deferred HTTP2 DATA bridge');
ok(!$ws_tx->is_terminal, 'WebSocket stream stays active after handshake');

$client_ws->send_text('from-client');
$ws_tx->write($client_ws->output);
pump();
is_deeply(\@messages, [['from-client', 'text']],
    'WebSocket frame delivered through a streamed H2 request');
is_deeply(\@client_messages, ['welcome', 'echo:from-client'],
    'WebSocket frame echoed over same H2 response stream');

my ($ordinary_body, $ordinary_finished) = ('', 0);
$h2client->request(
    method => 'GET', target => '/ordinary',
    scheme => 'https', authority => 'example.test',
    on_data => sub { $ordinary_body .= $_[1] },
    on_complete => sub { $ordinary_finished++ },
    on_error => sub { push @errors, "ordinary:$_[1]" },
);
pump();
is($ordinary_body, 'ordinary-ok',
    'ordinary HTTP2 requests work concurrently with WebSocket');
is($ordinary_finished, 1, 'ordinary request completed independently');
is_deeply(\@ordinary, ['/ordinary'],
    'WebSocket requests never reach ordinary on_request');
ok(!$ws_tx->is_terminal, 'ordinary request did not retire WebSocket stream');

my ($denied_handshake, $denied_request) =
    Unblock::WebSocket::Handshake->client_request(
        'wss://example.test/deny', http_version => '2',
    );
my $denied_status;
$h2client->request(
    $denied_request,
    stream_body => 1,
    on_response => sub { $denied_status = $_[1]->status },
);
pump();
is($denied_status, 403, 'application may deny H2 Extended CONNECT');
is_deeply(\@server_events,
    ['offer:/chat', 'open:/chat', 'offer:/deny'],
    'denial does not create a WebSocket session');

require Uniform::HTTP::Request;
my $bad_request = Uniform::HTTP::Request->new(
    method => 'CONNECT', protocol => 'websocket',
    target => '/bad', scheme => 'https', authority => 'example.test',
    version => '2',
    headers => [ [ 'Sec-WebSocket-Version' => '12' ] ],
);
my $bad_status;
$h2client->request($bad_request,
    stream_body => 1,
    on_response => sub { $bad_status = $_[1]->status });
pump();
is($bad_status, 400, 'invalid H2 handshake rejected without stream takeover');
ok(!$ws_tx->is_terminal, 'malformed sibling request cannot disrupt active WS');
is_deeply(\@errors, [], 'independent streams report no HTTP2 errors');
is_deeply($host->{aborted}, [], 'WebSocket does not abort H2 connection');

$client_ws->close;
$ws_tx->write($client_ws->output);
pump();
ok($server_ws->close_received, 'server received WebSocket Close frame');
ok($client_ws->close_received, 'client received WebSocket Close reply');
$ws_tx->end;
pump();
ok($server_tx->is_terminal, 'server WebSocket H2 transaction terminates after END_STREAM');
ok($ws_tx->is_terminal, 'client WebSocket H2 transaction also terminates');
is_deeply($host->{aborted}, [], 'WebSocket Close does not abort H2 transport');

my $after_close = '';
$h2client->request(
    method => 'GET', target => '/after-close',
    scheme => 'https', authority => 'example.test',
    on_data => sub { $after_close .= $_[1] },
);
pump();
is($after_close, 'ordinary-ok', 'HTTP2 remains usable after WebSocket Close');

for my $case (
    [ sub {
        Unblock::HTTP::Server->new(
            http2 => { websocket => 1 },
            on_request => sub {}, on_websocket => sub {},
        );
      }, qr/requires a defer callback/ ],
    [ sub {
        Unblock::HTTP::Server->new(
            http2 => { websocket => 1, enable_connect_protocol => 0 },
            on_request => sub {}, on_websocket => sub {},
            defer => sub {},
        );
      }, qr/requires enable_connect_protocol/ ],
    [ sub {
        Unblock::HTTP::Server->new(
            http2 => { websocket => 1, settings => { 8 => 0 } },
            on_request => sub {}, on_websocket => sub {},
            defer => sub {},
        );
      }, qr/conflicts with settings/ ],
) {
    ok(!eval { $case->[0]->(); 1 }, 'unsafe H2 WebSocket policy rejected');
    like($@, $case->[1], 'invalid policy explains requirement');
}

done_testing;
