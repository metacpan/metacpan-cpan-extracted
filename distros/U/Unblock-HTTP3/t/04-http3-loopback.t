use strict;
use warnings;

use FindBin ();
use IO::Select;
use IO::Socket::INET;
use Scalar::Util qw(refaddr);
use Test2::V0;
use Time::HiRes qw(time);

use Unblock::HTTP3::Capsule;
use Unblock::HTTP3::Connection;
use Net::QUIC;
use Net::QUIC::Driver;
use Uniform::HTTP::Request;
use Uniform::HTTP::Response;

is($Net::QUIC::VERSION, '0.04', 'vertical slice uses CPAN Net::QUIC 0.04');

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

my $client_extension_settings_calls = 0;
my $server_extension_settings_calls = 0;
my $client_extension_stream;
my $client_extension_stream_data = '';
my $client_extension_stream_ended = 0;
my $server_extension_stream;

my $client_h3 = Unblock::HTTP3::Connection->client(
    quic              => $client_quic,
    send_buffer_limit => 4096,
    extension_settings => {
        4660 => 7,
        4661 => 11,
    },
    on_extension_settings => sub {
        my ($connection, $settings) = @_;

        die "client received unexpected extension SETTINGS"
            unless scalar(keys %$settings) == 1
                && defined($settings->{4662})
                && $settings->{4662} eq '13';

        ++$client_extension_settings_calls;
        return;
    },
    extension_stream_handlers => {
        85 => sub {
            my ($connection, $stream) = @_;

            $client_extension_stream = $stream;
            $stream->configure(
                on_data => sub {
                    my ($extension, $bytes) = @_;
                    $client_extension_stream_data .= $bytes;
                    return;
                },
                on_end => sub {
                    $client_extension_stream_ended = 1;
                    return;
                },
            );

            return;
        },
    },
);
my $server_h3 = Unblock::HTTP3::Connection->server(
    quic                    => $server_quic,
    send_buffer_limit       => 4096,
    max_field_section_size  => 1024,
    max_buffered_body_bytes => 1024,
    enable_extended_connect => 1,
    extension_settings      => {
        4662 => 13,
    },
    on_extension_settings => sub {
        my ($connection, $settings) = @_;

        die "server received unexpected extension SETTINGS"
            unless scalar(keys %$settings) == 2
                && defined($settings->{4660})
                && $settings->{4660} eq '7'
                && defined($settings->{4661})
                && $settings->{4661} eq '11';

        ++$server_extension_settings_calls;
        return;
    },
    extension_stream_handlers => {
        84 => sub {
            my ($connection, $stream) = @_;
            $server_extension_stream = $stream;
            return;
        },
    },
);

$client_h3->start;
$server_h3->start;

ok($client_h3->started, 'client HTTP/3 connection is started');
ok($server_h3->started, 'server HTTP/3 connection is started');

ok(
    run_until(sub {
        return $client_h3->peer_settings_received
            && $server_h3->peer_settings_received;
    }),
    'client and server receive peer HTTP/3 SETTINGS',
);

is(
    $client_h3->peer_extension_settings,
    { 4662 => '13' },
    'client receives arbitrary server extension SETTINGS',
);

is(
    $server_h3->peer_extension_settings,
    {
        4660 => '7',
        4661 => '11',
    },
    'server receives arbitrary client extension SETTINGS',
);

is($client_h3->peer_extension_setting(4662), '13',
    'client can inspect one peer extension SETTING');
is($server_h3->peer_extension_setting(4660), '7',
    'server can inspect one peer extension SETTING');
is($client_extension_settings_calls, 1,
    'client extension SETTINGS validator runs once');
is($server_extension_settings_calls, 1,
    'server extension SETTINGS validator runs once');

ok($server_h3->extended_connect_enabled,
    'server advertises Extended CONNECT support');
ok($client_h3->peer_extended_connect_enabled,
    'client observes peer Extended CONNECT support');
ok(!$server_h3->peer_extended_connect_enabled,
    'server does not invent Extended CONNECT support for the client');

my $client_extension_out =
    $client_h3->open_extension_stream(84);
isa_ok($client_extension_out, ['Unblock::HTTP3::Extension::Stream']);
is($client_extension_out->type, '84',
    'outgoing extension stream exposes its type');
ok($client_extension_out->can_send,
    'outgoing extension stream is writable');
ok(!$client_extension_out->can_receive,
    'outgoing extension stream is unidirectional');

$client_extension_out->send('client-extension-stream');
$client_extension_out->finish;

ok(
    run_until(sub {
        return defined $server_extension_stream;
    }),
    'server dispatches registered extension stream type',
);

is($server_extension_stream->type, '84',
    'incoming extension stream preserves its type');
ok($server_extension_stream->incoming,
    'peer extension stream is marked incoming');

my $server_extension_data = '';

ok(
    run_until(sub {
        while (defined(my $chunk = $server_extension_stream->next_chunk)) {
            $server_extension_data .= $chunk;
        }

        return $server_extension_stream->is_complete;
    }),
    'server polls extension stream through clean FIN',
);

is($server_extension_data, 'client-extension-stream',
    'server receives extension stream payload without type prefix');

my $server_extension_out =
    $server_h3->open_extension_stream(85);
isa_ok($server_extension_out, ['Unblock::HTTP3::Extension::Stream']);

$server_extension_out->send('server-extension-stream');
$server_extension_out->finish;

ok(
    run_until(sub {
        return defined($client_extension_stream)
            && $client_extension_stream_ended;
    }),
    'client callback receives and finishes extension stream',
);

is($client_extension_stream_data, 'server-extension-stream',
    'extension stream callback receives payload bytes');

like(
    dies { $client_h3->open_extension_stream(0) },
    qr/stream type 0 is managed by Unblock::HTTP3/,
    'core HTTP/3 stream types cannot be opened as extensions',
);

like(
    dies { $client_h3->open_extension_stream(33) },
    qr/reserved for greasing/,
    'GREASE stream types cannot acquire extension semantics',
);

my $unknown_extension_out =
    $client_h3->open_extension_stream(86);
$unknown_extension_out->send('ignored-extension-stream');
$unknown_extension_out->finish;

ok(
    run_until(sub {
        return $unknown_extension_out->is_complete;
    }),
    'unregistered extension stream can be sent and ignored by peer',
);

ok(!$server_h3->failed,
    'unknown extension stream does not fail HTTP/3 connection');

ok(
    run_until(sub {
        return "$client_h3->{peer_max_field_section_size}" eq '1024';
    }),
    'client receives peer SETTINGS_MAX_FIELD_SECTION_SIZE',
);

my $stream_count_before_large_headers =
    scalar keys %{ $client_h3->{streams} };

my $oversized_headers_request = Uniform::HTTP::Request->new(
    method    => 'GET',
    target    => '/too-many-headers',
    scheme    => 'https',
    authority => 'localhost',
    headers   => [
        [ 'x-large', 'x' x 2000 ],
    ],
);

like(
    dies { $client_h3->request($oversized_headers_request) },
    qr/exceeds peer SETTINGS_MAX_FIELD_SECTION_SIZE 1024/,
    'client rejects a field section larger than the peer setting',
);

is(
    scalar(keys %{ $client_h3->{streams} }),
    $stream_count_before_large_headers,
    'oversized field section is rejected before opening a request stream',
);

my $outgoing_request = Uniform::HTTP::Request->new(
    method    => 'GET',
    target    => '/',
    scheme    => 'https',
    authority => 'localhost',
    headers   => [
        [ Priority   => 'u=5, i' ],
        [ cookie     => 'a=1' ],
        [ 'x-middle' => 'preserved' ],
        [ cookie     => 'b=2' ],
        [ cookie     => 'c=3; d=4' ],
    ],
);

my $client_transaction = $client_h3->request($outgoing_request);
isa_ok($client_transaction, ['Unblock::HTTP3::Transaction']);
is(
    refaddr($client_transaction->request),
    refaddr($outgoing_request),
    'client Transaction owns the submitted request',
);

my $server_transaction;

ok(
    run_until(sub {
        $server_transaction ||= $server_h3->next_transaction;
        return defined $server_transaction;
    }),
    'server receives HTTP/3 Transaction',
);

isa_ok($server_transaction, ['Unblock::HTTP3::Transaction']);

my $incoming_request = $server_transaction->request;

isa_ok($incoming_request, ['Uniform::HTTP::Request']);
is(ref($incoming_request), 'Uniform::HTTP::Request',
    'received request is the exact canonical Uniform class');
is($incoming_request->method, 'GET', 'server receives request method');
is($incoming_request->target, '/', 'server receives request target');
is($incoming_request->scheme, 'https', 'server receives request scheme');
is(
    $incoming_request->authority,
    'localhost',
    'server receives request authority',
);
is(
    $incoming_request->header_values('cookie'),
    [ 'a=1; b=2; c=3; d=4' ],
    'native receive path coalesces Cookie field lines',
);
is(
    [
        map {
            [
                $incoming_request->header_name($_),
                $incoming_request->header_value($_),
            ]
        } 0 .. $incoming_request->header_count - 1
    ],
    [
        [ 'priority', 'u=5, i' ],
        [ 'cookie', 'a=1; b=2; c=3; d=4' ],
        [ 'x-middle', 'preserved' ],
    ],
    'native receive path preserves field order around coalesced Cookie',
);

is(
    $client_transaction->priority,
    {
        urgency     => 5,
        incremental => 1,
    },
    'client Transaction starts with Request priority',
);

is(
    $server_transaction->priority,
    {
        urgency     => 5,
        incremental => 1,
    },
    'server applies initial RFC 9218 Priority field',
);

$client_transaction->priority(
    urgency     => 1,
    incremental => 0,
);

ok(
    run_until(sub {
        my $priority = $server_transaction->priority;
        return $priority->{urgency} == 1
            && !$priority->{incremental};
    }),
    'server receives client PRIORITY_UPDATE',
);

is(
    $client_transaction->priority,
    {
        urgency     => 1,
        incremental => 0,
    },
    'client Transaction remembers latest sent priority',
);

$server_transaction->priority(
    urgency     => 0,
    incremental => 1,
);

is(
    $server_transaction->priority,
    {
        urgency     => 0,
        incremental => 1,
    },
    'server can override stream priority for local scheduling',
);

my $early_hints = Uniform::HTTP::Response->new(
    status  => 103,
    headers => [
        [ 'link', '</style.css>; rel=preload; as=style' ],
    ],
);

$server_transaction->send_informational($early_hints);

my $informational_transaction;

ok(
    run_until(sub {
        $informational_transaction ||= $client_h3->next_informational;
        return defined $informational_transaction;
    }),
    'client receives informational HTTP/3 response event',
);

is(
    refaddr($informational_transaction),
    refaddr($client_transaction),
    'informational response belongs to the original Transaction',
);

my $received_early_hints = $client_transaction->next_informational;

isa_ok($received_early_hints, ['Uniform::HTTP::Response']);
is(ref($received_early_hints), 'Uniform::HTTP::Response',
    'received informational response is exact canonical Uniform');
is($received_early_hints->status, 103,
    'client receives 103 Early Hints status');
is(
    $received_early_hints->header('link'),
    '</style.css>; rel=preload; as=style',
    'client receives informational response headers',
);
ok(
    !defined($client_transaction->response),
    'informational response does not occupy final Response slot',
);

my $outgoing_response = $server_transaction->response;
isa_ok($outgoing_response, ['Uniform::HTTP::Response']);

$outgoing_response->status(200);
$outgoing_response->add_header(cookie => 'response-one=1');
$outgoing_response->add_header('x-response' => 'preserved');
$outgoing_response->add_header(cookie => 'response-two=2');
$server_transaction->send_response;

my $incoming_response;

ok(
    run_until(sub {
        $incoming_response ||= $client_transaction->response;
        return defined $incoming_response;
    }),
    'client Transaction receives HTTP/3 response',
);

isa_ok($incoming_response, ['Uniform::HTTP::Response']);
is(ref($incoming_response), 'Uniform::HTTP::Response',
    'received final response is the exact canonical Uniform class');
is($incoming_response->status, 200, 'client receives response status');
is(
    $incoming_response->header_values('cookie'),
    [ 'response-one=1; response-two=2' ],
    'native response receive path coalesces Cookie field lines',
);
is(
    [
        map {
            [
                $incoming_response->header_name($_),
                $incoming_response->header_value($_),
            ]
        } 0 .. $incoming_response->header_count - 1
    ],
    [
        [ 'cookie', 'response-one=1; response-two=2' ],
        [ 'x-response', 'preserved' ],
    ],
    'native response receive path preserves field order around Cookie',
);

my $ready_client_transaction = $client_h3->next_transaction;
is(
    refaddr($ready_client_transaction),
    refaddr($client_transaction),
    'client response event returns the original Transaction',
);

ok(
    run_until(sub {
        return $server_transaction->is_complete
            && $client_transaction->is_complete;
    }),
    'client and server Transactions finish cleanly',
);

my $completed_stream_id = $client_transaction->stream_id;

ok(
    run_until(sub {
        return !exists($client_h3->{transactions}{$completed_stream_id})
            && !exists($server_h3->{transactions}{$completed_stream_id})
            && !exists($client_h3->{streams}{$completed_stream_id})
            && !exists($server_h3->{streams}{$completed_stream_id});
    }),
    'closed completed stream state is released from both HTTP/3 connections',
);

is(
    $client_transaction->response->status,
    200,
    'application-retained Transaction remains usable after connection cleanup',
);

my $request_body = "hello over HTTP/3";
my $body_request = Uniform::HTTP::Request->new(
    method    => 'POST',
    target    => '/echo',
    scheme    => 'https',
    authority => 'localhost',
    headers   => [
        [ 'content-type', 'text/plain' ],
    ],
    body      => $request_body,
);

my $body_client_tx = $client_h3->request($body_request);
isa_ok($body_client_tx, ['Unblock::HTTP3::Transaction']);

my $body_server_tx;

ok(
    run_until(sub {
        $body_server_tx ||= $server_h3->next_transaction;
        return $body_server_tx
            && $body_server_tx->request->is_complete
            && $body_server_tx->request->has_buffered_body
            && $body_server_tx->request->body eq $request_body;
    }),
    'server receives the complete HTTP/3 request body',
);

my $received_body_request = $body_server_tx->request;

is(
    $received_body_request->header('content-type'),
    'text/plain',
    'request headers travel with a request body',
);

my $response_body = "HTTP/3 body response";
my $body_response = $body_server_tx->response;

$body_response->header('content-type', 'text/plain');
$body_response->body($response_body);
$body_server_tx->send_response;

my $received_body_response;

ok(
    run_until(sub {
        $received_body_response ||= $body_client_tx->response;

        return $received_body_response
            && $received_body_response->is_complete
            && $received_body_response->has_buffered_body
            && $received_body_response->body eq $response_body;
    }),
    'client receives the complete HTTP/3 response body',
);

is(
    $received_body_response->header('content-type'),
    'text/plain',
    'response headers travel with a response body',
);

ok(
    run_until(sub {
        return $body_server_tx->is_complete
            && $body_client_tx->is_complete;
    }),
    'body Transactions finish cleanly',
);

my $stream_request = Uniform::HTTP::Request->new(
    method    => 'POST',
    target    => '/stream-request',
    scheme    => 'https',
    authority => 'localhost',
    headers   => [
        [ 'content-type', 'text/plain' ],
    ],
);

my $stream_request_cancelled = 0;
my $stream_request_tx = $client_h3->request(
    $stream_request,
    stream_body => {
        on_cancel => sub {
            ++$stream_request_cancelled;
        },
    },
);

isa_ok($stream_request_tx, ['Unblock::HTTP3::Transaction']);

my $request_producer = $stream_request_tx->request_body;
isa_ok($request_producer, ['Unblock::HTTP3::Body::Stream']);

ok(
    $request_producer->write('stream-'),
    'small incremental request body write can continue',
);

$request_producer->complete('request');

ok($request_producer->is_complete,
    'incremental request producer is complete');
is($stream_request_cancelled, 0,
    'completed request producer was not cancelled');

my $stream_request_server_tx;

ok(
    run_until(sub {
        $stream_request_server_tx ||= $server_h3->next_transaction;

        return $stream_request_server_tx
            && $stream_request_server_tx->request->is_complete
            && $stream_request_server_tx->request->has_buffered_body
            && $stream_request_server_tx->request->body eq 'stream-request';
    }),
    'server receives incremental request body as one complete message',
);

$stream_request_server_tx->send_response;

ok(
    run_until(sub {
        return $stream_request_tx->is_complete
            && $stream_request_server_tx->is_complete;
    }),
    'incremental request Transaction finishes cleanly',
);

my $stream_response_request = Uniform::HTTP::Request->new(
    method    => 'GET',
    target    => '/stream-response',
    scheme    => 'https',
    authority => 'localhost',
);

my $received_stream_response_body = '';
my $received_stream_response_end = 0;

my $stream_response_client_tx = $client_h3->request(
    $stream_response_request,
    receive_body => {
        on_data => sub {
            my ($reader, $chunk) = @_;
            $received_stream_response_body .= $chunk;
        },
        on_end => sub {
            ++$received_stream_response_end;
        },
    },
);
my $stream_response_server_tx;

ok(
    run_until(sub {
        $stream_response_server_tx ||= $server_h3->next_transaction;
        return $stream_response_server_tx
            && $stream_response_server_tx->request->is_complete;
    }),
    'server receives request for incremental response',
);

my $stream_response = $stream_response_server_tx->response;
$stream_response->header('content-type', 'text/plain');

my $response_drains = 0;
my $response_cancelled = 0;

my $response_producer = $stream_response_server_tx->response_body(
    on_drain => sub {
        ++$response_drains;
    },
    on_cancel => sub {
        ++$response_cancelled;
    },
);

isa_ok($response_producer, ['Unblock::HTTP3::Body::Stream']);

ok(
    !$response_producer->write('R' x 8192),
    'large incremental response body applies producer backpressure',
);

ok(
    run_until(sub {
        return $response_drains > 0;
    }),
    'incremental response producer receives on_drain after ACK progress',
);

$response_producer->complete('tail');

ok($response_producer->is_complete,
    'incremental response producer is complete');
is($response_cancelled, 0,
    'completed response producer was not cancelled');

my $streamed_response;

ok(
    run_until(sub {
        $streamed_response ||= $stream_response_client_tx->response;

        return $streamed_response
            && $stream_response_client_tx->is_complete
            && $received_stream_response_end == 1;
    }),
    'client streams the complete incrementally produced response body',
);

is(
    $received_stream_response_body,
    (('R' x 8192) . 'tail'),
    'client receive callback sees the complete response body',
);

ok(
    !$streamed_response->has_buffered_body,
    'streamed response body is not duplicated into the Response object',
);

my $response_reader = $stream_response_client_tx->response_body;
isa_ok($response_reader, ['Unblock::HTTP3::Body::Reader']);
ok($response_reader->is_complete,
    'client response body reader is complete');
is($response_reader->pending_bytes, 0,
    'client response body reader has no pending bytes');

is(
    $streamed_response->header('content-type'),
    'text/plain',
    'incremental response headers are preserved',
);

ok(
    run_until(sub {
        return $stream_response_client_tx->is_complete
            && $stream_response_server_tx->is_complete;
    }),
    'incremental response Transactions finish cleanly',
);

$server_h3->receive_body_mode('stream');

my $receive_stream_request = Uniform::HTTP::Request->new(
    method    => 'POST',
    target    => '/receive-stream',
    scheme    => 'https',
    authority => 'localhost',
);

my $receive_stream_client_tx = $client_h3->request(
    $receive_stream_request,
    stream_body => {},
);

my $receive_request_writer = $receive_stream_client_tx->request_body;
$receive_request_writer->write('incoming-');
$receive_request_writer->complete('stream-body');

my $receive_stream_server_tx;

ok(
    run_until(sub {
        $receive_stream_server_tx ||= $server_h3->next_transaction;
        return $receive_stream_server_tx
            && $receive_stream_server_tx->request->is_complete
            && $receive_stream_server_tx->request_body->pending_bytes > 0;
    }),
    'server queues an incoming body without buffering it into Request',
);

my $request_reader = $receive_stream_server_tx->request_body;
isa_ok($request_reader, ['Unblock::HTTP3::Body::Reader']);

ok(
    !$receive_stream_server_tx->is_complete,
    'server Transaction waits for application body consumption',
);

ok(
    !$receive_stream_server_tx->request->has_buffered_body,
    'streamed request body is not duplicated into the Request object',
);

my $received_request_body = '';

while (!$request_reader->is_complete) {
    while (defined(my $chunk = $request_reader->next_chunk)) {
        $received_request_body .= $chunk;
    }

    service_once(time() + 1)
        unless $request_reader->is_complete;
}

is(
    $received_request_body,
    'incoming-stream-body',
    'server reader returns the complete request body',
);

is($request_reader->pending_bytes, 0,
    'server reader returns all queued receive credit');

$receive_stream_server_tx->send_response;

ok(
    run_until(sub {
        return $receive_stream_client_tx->is_complete
            && $receive_stream_server_tx->is_complete;
    }),
    'receive-streaming request Transactions finish cleanly',
);

$server_h3->receive_body_mode('buffered');

my $stream_trailer_request = Uniform::HTTP::Request->new(
    method    => 'POST',
    target    => '/stream-trailers',
    scheme    => 'https',
    authority => 'localhost',
    trailers  => [
        [ 'x-request-tail', 'request-tail' ],
    ],
);

my $stream_trailer_client_tx = $client_h3->request(
    $stream_trailer_request,
    stream_body => {},
);

my $stream_trailer_request_body =
    $stream_trailer_client_tx->request_body;

$stream_trailer_request_body->write('streaming-');
$stream_trailer_request_body->complete('request-with-trailer');

my $stream_trailer_server_tx;

ok(
    run_until(sub {
        $stream_trailer_server_tx ||= $server_h3->next_transaction;

        return $stream_trailer_server_tx
            && $stream_trailer_server_tx->request->is_complete
            && $stream_trailer_server_tx->request->has_buffered_body
            && $stream_trailer_server_tx->request->trailer_count == 1;
    }),
    'server receives streaming request body followed by trailers',
);

is(
    $stream_trailer_server_tx->request->body,
    'streaming-request-with-trailer',
    'streaming request body is complete before trailers',
);

is(
    $stream_trailer_server_tx->request->trailer('x-request-tail'),
    'request-tail',
    'streaming request trailer is preserved',
);

my $stream_trailer_response = $stream_trailer_server_tx->response;
$stream_trailer_response->add_trailer(
    'x-response-tail',
    'response-tail',
);

my $stream_trailer_response_body =
    $stream_trailer_server_tx->response_body;

$stream_trailer_response_body->write('streaming-');
$stream_trailer_response_body->complete('response-with-trailer');

my $received_stream_trailer_response;

ok(
    run_until(sub {
        $received_stream_trailer_response ||=
            $stream_trailer_client_tx->response;

        return $received_stream_trailer_response
            && $received_stream_trailer_response->is_complete
            && $received_stream_trailer_response->has_buffered_body
            && $received_stream_trailer_response->trailer_count == 1;
    }),
    'client receives streaming response body followed by trailers',
);

is(
    $received_stream_trailer_response->body,
    'streaming-response-with-trailer',
    'streaming response body is complete before trailers',
);

is(
    $received_stream_trailer_response->trailer('x-response-tail'),
    'response-tail',
    'streaming response trailer is preserved',
);

ok(
    run_until(sub {
        return $stream_trailer_client_tx->is_complete
            && $stream_trailer_server_tx->is_complete;
    }),
    'streaming body and trailer Transactions finish cleanly',
);

my $trailer_request = Uniform::HTTP::Request->new(
    method    => 'POST',
    target    => '/trailers',
    scheme    => 'https',
    authority => 'localhost',
    body      => 'request with trailers',
    trailers  => [
        [ 'x-request-checksum', 'abc123' ],
        [ 'x-repeat', 'one' ],
        [ 'x-repeat', 'two' ],
    ],
);

my $trailer_client_tx = $client_h3->request($trailer_request);
my $trailer_server_tx;

ok(
    run_until(sub {
        $trailer_server_tx ||= $server_h3->next_transaction;

        return $trailer_server_tx
            && $trailer_server_tx->request->is_complete
            && $trailer_server_tx->request->trailer_count == 3;
    }),
    'server receives complete request trailers',
);

my $received_trailer_request = $trailer_server_tx->request;

is(
    $received_trailer_request->trailer('x-request-checksum'),
    'abc123',
    'request trailer value is preserved',
);

is(
    $received_trailer_request->trailer_values('x-repeat'),
    [ 'one', 'two' ],
    'repeated request trailers are preserved',
);

my $trailer_response = $trailer_server_tx->response;
$trailer_response->body('response with trailers');
$trailer_response->add_trailer('x-response-checksum', 'def456');
$trailer_server_tx->send_response;

my $received_trailer_response;

ok(
    run_until(sub {
        $received_trailer_response ||= $trailer_client_tx->response;

        return $received_trailer_response
            && $received_trailer_response->is_complete
            && $received_trailer_response->trailer_count == 1;
    }),
    'client receives complete response trailers',
);

is(
    $received_trailer_response->trailer('x-response-checksum'),
    'def456',
    'response trailer value is preserved',
);

ok(
    run_until(sub {
        return $trailer_server_tx->is_complete
            && $trailer_client_tx->is_complete;
    }),
    'trailer Transactions finish cleanly',
);

my @multi_client_tx;

for my $index (1 .. 4) {
    my $request = Uniform::HTTP::Request->new(
        method    => 'GET',
        target    => "/multi/$index",
        scheme    => 'https',
        authority => 'localhost',
    );

    push @multi_client_tx, $client_h3->request($request);
}

my @multi_server_tx;

ok(
    run_until(sub {
        while (my $tx = $server_h3->next_transaction) {
            push @multi_server_tx, $tx;
        }

        return @multi_server_tx == 4;
    }),
    'server receives four concurrent HTTP/3 Transactions',
);

for my $tx (reverse @multi_server_tx) {
    my $path = $tx->request->target;
    $tx->response->body("response:$path");
    $tx->send_response;
}

ok(
    run_until(sub {
        for my $tx (@multi_client_tx) {
            my $response = $tx->response;
            return 0 unless $response && $response->is_complete;
        }

        return 1;
    }),
    'client receives all out-of-order multiplexed responses',
);

for my $index (1 .. 4) {
    my $tx = $multi_client_tx[$index - 1];

    is(
        $tx->response->body,
        "response:/multi/$index",
        "multiplexed response $index stays paired with its request",
    );
}

ok(
    run_until(sub {
        for my $tx (@multi_client_tx, @multi_server_tx) {
            return 0 unless $tx->is_complete;
        }

        return 1;
    }),
    'all multiplexed Transactions finish cleanly',
);

my $uniform_request = Uniform::HTTP::Request->new(
    method    => 'GET',
    target    => '/uniform-direct',
    scheme    => 'https',
    authority => 'localhost',
);

my $uniform_client_tx = $client_h3->request($uniform_request);
isa_ok($uniform_client_tx, ['Unblock::HTTP3::Transaction']);
is(refaddr($uniform_client_tx->request), refaddr($uniform_request),
    'client Transaction retains the submitted Uniform Request directly');
ok(!$uniform_request->is_mutable,
    'submitted Uniform Request is frozen after HTTP/3 takes its field snapshot');

my $uniform_server_tx;

ok(
    run_until(sub {
        $uniform_server_tx ||= $server_h3->next_transaction;
        return defined $uniform_server_tx;
    }),
    'server receives a request submitted as a plain Uniform object',
);

isa_ok($uniform_server_tx->request, ['Uniform::HTTP::Request']);
is($uniform_server_tx->request->target, '/uniform-direct',
    'plain Uniform request semantics survive the HTTP/3 wire path');

$uniform_server_tx->response->status(204);
$uniform_server_tx->send_response;

ok(
    run_until(sub {
        return $uniform_client_tx->is_complete
            && $uniform_server_tx->is_complete;
    }),
    'plain Uniform request completes a real HTTP/3 exchange',
);
is($uniform_client_tx->response->status, 204,
    'plain Uniform request receives its HTTP/3 response');

my $uniform_stream_request = Uniform::HTTP::Request->new(
    method    => 'POST',
    target    => '/uniform-stream',
    scheme    => 'https',
    authority => 'localhost',
);

my $uniform_stream_client_tx = $client_h3->request(
    $uniform_stream_request,
    stream_body => {},
);
my $uniform_stream_writer = $uniform_stream_client_tx->request_body;

ok(!$uniform_stream_request->is_complete,
    'plain Uniform Request tracks externally managed streaming progress');

$uniform_stream_writer->write('partial-');

my $uniform_stream_server_tx;

ok(
    run_until(sub {
        $uniform_stream_server_tx ||= $server_h3->next_transaction;
        return defined $uniform_stream_server_tx;
    }),
    'server receives streaming request submitted as a plain Uniform object',
);

ok(!$uniform_stream_server_tx->request->is_complete,
    'received streaming Uniform message remains incomplete before FIN');
ok(!$uniform_stream_server_tx->request->has_buffered_body,
    'partial network DATA is not exposed as a complete Uniform body');

$uniform_stream_writer->complete('body');

ok(
    run_until(sub {
        return $uniform_stream_server_tx->request->is_complete
            && $uniform_stream_server_tx->request->has_buffered_body;
    }),
    'complete buffered body is installed only when the HTTP message ends',
);

is($uniform_stream_server_tx->request->body, 'partial-body',
    'Uniform body contains the complete received body');
ok($uniform_stream_client_tx->request->is_complete,
    'outgoing Uniform Request becomes complete when body production finishes');

$uniform_stream_server_tx->response->status(204);
$uniform_stream_server_tx->send_response;

ok(
    run_until(sub {
        return $uniform_stream_client_tx->is_complete
            && $uniform_stream_server_tx->is_complete;
    }),
    'streaming plain Uniform request completes cleanly',
);

my $unnegotiated_extended = Uniform::HTTP::Request->new(
    method    => 'CONNECT',
    protocol  => 'test-protocol',
    scheme    => 'https',
    authority => 'localhost',
    target    => '/unnegotiated',
);

$client_h3->{peer_enable_connect_protocol} = 0;

like(
    dies { $client_h3->request($unnegotiated_extended) },
    qr/peer did not enable Extended CONNECT/,
    'client refuses Extended CONNECT before peer capability is negotiated',
);

ok($unnegotiated_extended->is_mutable,
    'failed capability check does not commit the Request');
ok($unnegotiated_extended->is_complete,
    'failed capability check does not start external streaming state');

$client_h3->{peer_enable_connect_protocol} = 1;

my $extended_request = Uniform::HTTP::Request->new(
    method    => 'CONNECT',
    protocol  => 'test-protocol',
    scheme    => 'https',
    authority => 'localhost',
    target    => '/extended',
);

my $extended_client_tx = $client_h3->request($extended_request);
isa_ok($extended_client_tx, ['Unblock::HTTP3::Transaction']);
ok($extended_client_tx->is_extended_connect,
    'client Transaction identifies Extended CONNECT');
is($extended_client_tx->protocol, 'test-protocol',
    'client Transaction exposes Extended CONNECT protocol');

my $extended_client_writer = $extended_client_tx->request_body;
isa_ok($extended_client_writer, ['Unblock::HTTP3::Body::Stream']);

my $extended_server_tx;

ok(
    run_until(sub {
        $extended_server_tx ||= $server_h3->next_transaction;
        return defined $extended_server_tx;
    }),
    'server receives Extended CONNECT Transaction',
);

ok($extended_server_tx->is_extended_connect,
    'server Transaction identifies Extended CONNECT');
is($extended_server_tx->protocol, 'test-protocol',
    'server Transaction exposes selected protocol');
is($extended_server_tx->request->method, 'CONNECT',
    'Extended CONNECT preserves CONNECT method');
is($extended_server_tx->request->scheme, 'https',
    'Extended CONNECT preserves :scheme');
is($extended_server_tx->request->authority, 'localhost',
    'Extended CONNECT preserves :authority');
is($extended_server_tx->request->target, '/extended',
    'Extended CONNECT preserves :path');

my $extended_server_reader = $extended_server_tx->request_body;
isa_ok($extended_server_reader, ['Unblock::HTTP3::Body::Reader']);

my $extended_server_writer = $extended_server_tx->response_body;
isa_ok($extended_server_writer, ['Unblock::HTTP3::Body::Stream']);

$extended_server_writer->write('extended-server-to-client');

ok(
    run_until(sub {
        my $response = $extended_client_tx->response;
        return $response && $response->status == 200;
    }),
    'client receives successful Extended CONNECT response',
);

my $extended_client_reader = $extended_client_tx->response_body;
isa_ok($extended_client_reader, ['Unblock::HTTP3::Body::Reader']);

$extended_client_writer->write('extended-client-to-server');

ok(
    run_until(sub {
        return $extended_server_reader->pending_bytes > 0
            && $extended_client_reader->pending_bytes > 0;
    }),
    'Extended CONNECT carries DATA in both directions',
);

my $extended_to_server = '';
while (defined(my $chunk = $extended_server_reader->next_chunk)) {
    $extended_to_server .= $chunk;
}

my $extended_to_client = '';
while (defined(my $chunk = $extended_client_reader->next_chunk)) {
    $extended_to_client .= $chunk;
}

is($extended_to_server, 'extended-client-to-server',
    'server reads Extended CONNECT client DATA');
is($extended_to_client, 'extended-server-to-client',
    'client reads Extended CONNECT server DATA');

$extended_client_writer->complete;

ok(
    run_until(sub {
        return $extended_server_reader->is_complete;
    }),
    'server observes Extended CONNECT client half-close',
);

$extended_server_writer->complete;

ok(
    run_until(sub {
        return $extended_client_reader->is_complete
            && $extended_client_tx->is_complete
            && $extended_server_tx->is_complete;
    }),
    'Extended CONNECT completes after both DATA directions close',
);

my $unsupported_extended = Uniform::HTTP::Request->new(
    method    => 'CONNECT',
    protocol  => 'unsupported-protocol',
    scheme    => 'https',
    authority => 'localhost',
    target    => '/unsupported',
);

my $unsupported_client_tx = $client_h3->request($unsupported_extended);
my $unsupported_writer = $unsupported_client_tx->request_body;
my $unsupported_server_tx;

ok(
    run_until(sub {
        $unsupported_server_tx ||= $server_h3->next_transaction;
        return defined $unsupported_server_tx;
    }),
    'server receives protocol-neutral Extended CONNECT request',
);

is($unsupported_server_tx->protocol, 'unsupported-protocol',
    'application can inspect an unsupported protocol identifier');

$unsupported_server_tx->response->status(501);
$unsupported_server_tx->send_response;

ok(
    run_until(sub {
        my $response = $unsupported_client_tx->response;
        return $response
            && $response->status == 501
            && $unsupported_writer->is_complete
            && $unsupported_client_tx->is_complete
            && $unsupported_server_tx->is_complete;
    }),
    'application can reject an unsupported Extended CONNECT protocol with 501',
);

my $capsule_request = Uniform::HTTP::Request->new(
    method    => 'CONNECT',
    protocol  => 'capsule-test',
    scheme    => 'https',
    authority => 'localhost',
    target    => '/capsules',
    headers   => [
        [ 'capsule-protocol', '?1' ],
    ],
);

my $capsule_client_tx = $client_h3->request($capsule_request);

like(
    dies { $capsule_client_tx->capsules },
    qr/requires a final response/,
    'client does not activate Capsule Protocol before a final response',
);

my $capsule_server_tx;

ok(
    run_until(sub {
        $capsule_server_tx ||= $server_h3->next_transaction;
        return defined $capsule_server_tx;
    }),
    'server receives Extended CONNECT used for Capsule Protocol',
);

$capsule_server_tx->response->header('capsule-protocol', '?1');

my @server_capsules;
my $capsule_server_stream = $capsule_server_tx->capsules(
    handlers => {
        42 => sub {
            my ($stream, $capsule) = @_;
            push @server_capsules, [
                $capsule->type,
                $capsule->value,
            ];
        },
    },
);

isa_ok($capsule_server_stream, ['Unblock::HTTP3::Capsule::Stream']);

$capsule_server_stream->send(7, 'server-ready');

ok(
    run_until(sub {
        my $response = $capsule_client_tx->response;
        return $response && $response->status == 200;
    }),
    'client receives successful response before activating Capsule Protocol',
);

my $capsule_client_stream = $capsule_client_tx->capsules;
isa_ok($capsule_client_stream, ['Unblock::HTTP3::Capsule::Stream']);

my $server_ready_capsule;

ok(
    run_until(sub {
        $server_ready_capsule ||=
            $capsule_client_stream->next_capsule;
        return defined $server_ready_capsule;
    }),
    'client receives server Capsule after activating Capsule Protocol',
);

is($server_ready_capsule->type, '7',
    'client receives server Capsule type');
is($server_ready_capsule->value, 'server-ready',
    'client receives server Capsule value');

$capsule_client_stream->send(99, 'unknown-is-ignored');
$capsule_client_stream->send(42, 'client-capsule');

ok(
    run_until(sub {
        return @server_capsules == 1;
    }),
    'server Capsule type dispatch receives the registered type',
);

is(
    \@server_capsules,
    [ [ '42', 'client-capsule' ] ],
    'unregistered Capsule type is silently skipped',
);

$capsule_client_stream->complete;

ok(
    run_until(sub {
        return $capsule_server_stream->is_receive_complete;
    }),
    'server Capsule parser observes a clean client half-close',
);

$capsule_server_stream->send(8, 'after-client-half-close');
$capsule_server_stream->complete;

my $after_half_close_capsule;

ok(
    run_until(sub {
        $after_half_close_capsule ||=
            $capsule_client_stream->next_capsule;

        return defined($after_half_close_capsule)
            && $capsule_client_stream->is_receive_complete
            && $capsule_client_tx->is_complete
            && $capsule_server_tx->is_complete;
    }),
    'server can send Capsules after the client half-closes',
);

is($after_half_close_capsule->type, '8',
    'post-half-close Capsule type is preserved');
is($after_half_close_capsule->value, 'after-client-half-close',
    'post-half-close Capsule value is preserved');

my $malformed_capsule_request = Uniform::HTTP::Request->new(
    method    => 'CONNECT',
    protocol  => 'capsule-test',
    scheme    => 'https',
    authority => 'localhost',
    target    => '/malformed-capsule',
    headers   => [
        [ 'capsule-protocol', '?1' ],
    ],
);

my $malformed_capsule_client_tx =
    $client_h3->request($malformed_capsule_request);
my $malformed_capsule_writer =
    $malformed_capsule_client_tx->request_body;
my $malformed_capsule_server_tx;

ok(
    run_until(sub {
        $malformed_capsule_server_tx ||= $server_h3->next_transaction;
        return defined $malformed_capsule_server_tx;
    }),
    'server receives Capsule Protocol truncation test request',
);

$malformed_capsule_server_tx->response->header(
    'capsule-protocol',
    '?1',
);

my $malformed_capsule_server_stream =
    $malformed_capsule_server_tx->capsules(
        on_capsule => sub { },
    );

$malformed_capsule_server_stream->send(1, 'ready');

ok(
    run_until(sub {
        my $response = $malformed_capsule_client_tx->response;
        return $response && $response->status == 200;
    }),
    'malformed Capsule test establishes Capsule Protocol first',
);

$malformed_capsule_writer->write("\x2a\x05ab");
$malformed_capsule_writer->complete;

ok(
    run_until(sub {
        my $response = $malformed_capsule_client_tx->response;

        return $malformed_capsule_server_tx->state eq 'error'
            && defined($response)
            && defined($malformed_capsule_client_tx->remote_reset_code);
    }),
    'truncated Capsule aborts only its HTTP/3 request stream',
);

like(
    $malformed_capsule_server_tx->error,
    qr/Capsule Protocol.*truncated Capsule/,
    'truncated Capsule records a useful Transaction error',
);

is(
    $malformed_capsule_client_tx->remote_reset_code,
    0x010e,
    'truncated Capsule records remote H3_MESSAGE_ERROR on Transaction',
);

ok(!$server_h3->failed,
    'malformed Capsule does not fail the HTTP/3 connection');

my $connect_request = Uniform::HTTP::Request->new(
    method    => 'CONNECT',
    target    => 'example.test:443',
    authority => 'example.test:443',
);

my $connect_client_tx = $client_h3->request($connect_request);
isa_ok($connect_client_tx, ['Unblock::HTTP3::Transaction']);

my $connect_client_writer = $connect_client_tx->request_body;
isa_ok($connect_client_writer, ['Unblock::HTTP3::Body::Stream']);

my $connect_server_tx;

ok(
    run_until(sub {
        $connect_server_tx ||= $server_h3->next_transaction;
        return defined $connect_server_tx;
    }),
    'server receives basic HTTP/3 CONNECT Transaction',
);

is($connect_server_tx->request->method, 'CONNECT',
    'server receives CONNECT method');
is($connect_server_tx->request->target, 'example.test:443',
    'CONNECT target is authority-form');
is($connect_server_tx->request->authority, 'example.test:443',
    'CONNECT authority is preserved');
is($connect_server_tx->request->scheme, undef,
    'basic CONNECT has no scheme');
is($connect_server_tx->protocol, undef,
    'basic CONNECT has no Extended CONNECT protocol');
ok(!$connect_server_tx->is_extended_connect,
    'basic CONNECT remains distinct from Extended CONNECT');

my $connect_server_reader = $connect_server_tx->request_body;
isa_ok($connect_server_reader, ['Unblock::HTTP3::Body::Reader']);

my $connect_server_writer = $connect_server_tx->response_body;
isa_ok($connect_server_writer, ['Unblock::HTTP3::Body::Stream']);

$connect_server_writer->write('server-to-client');

ok(
    run_until(sub {
        my $response = $connect_client_tx->response;
        return $response && $response->status == 200;
    }),
    'client receives successful CONNECT response',
);

my $connect_client_reader = $connect_client_tx->response_body;
isa_ok($connect_client_reader, ['Unblock::HTTP3::Body::Reader']);

$connect_client_writer->write('client-to-server');

ok(
    run_until(sub {
        return $connect_server_reader->pending_bytes > 0
            && $connect_client_reader->pending_bytes > 0;
    }),
    'both CONNECT tunnel directions carry DATA',
);

my $connect_to_server = '';
while (defined(my $chunk = $connect_server_reader->next_chunk)) {
    $connect_to_server .= $chunk;
}

my $connect_to_client = '';
while (defined(my $chunk = $connect_client_reader->next_chunk)) {
    $connect_to_client .= $chunk;
}

is($connect_to_server, 'client-to-server',
    'server reads client-to-server tunnel bytes');
is($connect_to_client, 'server-to-client',
    'client reads server-to-client tunnel bytes');

ok(!$connect_client_tx->is_complete,
    'CONNECT Transaction remains active while tunnel halves are open');

$connect_client_writer->complete;

ok(
    run_until(sub {
        return $connect_server_reader->is_complete;
    }),
    'server observes client tunnel half-close',
);

ok(!$connect_client_tx->is_complete,
    'client Transaction remains active until response tunnel half closes');

$connect_server_writer->complete;

ok(
    run_until(sub {
        return $connect_client_reader->is_complete
            && $connect_client_tx->is_complete
            && $connect_server_tx->is_complete;
    }),
    'CONNECT Transaction completes after both tunnel directions end',
);

my $rejected_connect = Uniform::HTTP::Request->new(
    method    => 'CONNECT',
    target    => 'reject.test:443',
    authority => 'reject.test:443',
);

my $rejected_client_tx = $client_h3->request($rejected_connect);
my $rejected_writer = $rejected_client_tx->request_body;
my $rejected_server_tx;

ok(
    run_until(sub {
        $rejected_server_tx ||= $server_h3->next_transaction;
        return defined $rejected_server_tx;
    }),
    'server receives CONNECT which will be rejected',
);

$rejected_server_tx->response->status(403);
$rejected_server_tx->send_response;

ok(
    run_until(sub {
        my $response = $rejected_client_tx->response;
        return $response
            && $response->status == 403
            && $rejected_writer->is_complete
            && $rejected_client_tx->is_complete
            && $rejected_server_tx->is_complete;
    }),
    'failed CONNECT closes unused client tunnel side and completes normally',
);

my $cancel_request = Uniform::HTTP::Request->new(
    method    => 'GET',
    target    => '/cancel',
    scheme    => 'https',
    authority => 'localhost',
);

my $cancel_client_tx = $client_h3->request($cancel_request);
my $cancel_server_tx;

ok(
    run_until(sub {
        $cancel_server_tx ||= $server_h3->next_transaction;
        return $cancel_server_tx
            && $cancel_server_tx->request->is_complete;
    }),
    'server receives request used for cancellation test',
);

my $large_response = $cancel_server_tx->response;
my $cancelled_producer_callbacks = 0;

my $cancel_response_producer = $cancel_server_tx->response_body(
    on_cancel => sub {
        ++$cancelled_producer_callbacks;
    },
);

ok(
    !$cancel_response_producer->write('x' x 65536),
    'large streaming response is backpressured before cancellation',
);

ok(
    $server_h3->{native}->streaming_retained_bytes > 0,
    'streaming response retains unacknowledged native body bytes',
);

my $received_cancel_response;

ok(
    run_until(sub {
        $received_cancel_response ||= $cancel_client_tx->response;
        return $received_cancel_response
            && !$received_cancel_response->is_complete;
    }),
    'client receives streaming response before its body is complete',
);

$cancel_client_tx->cancel;

ok(
    run_until(sub {
        return defined($cancel_server_tx->remote_stop_sending_code)
            && defined($cancel_client_tx->remote_reset_code)
            && $cancel_server_tx->is_cancelled
            && $cancel_response_producer->is_cancelled
            && $server_h3->{native}->streaming_retained_bytes == 0;
    }),
    'HTTP/3 cancellation releases the streaming producer and native buffers',
);

is(
    $cancelled_producer_callbacks,
    1,
    'streaming response on_cancel runs exactly once',
);

is(
    $cancel_client_tx->local_stop_sending_code,
    0x10c,
    'client Transaction records local STOP_SENDING H3_REQUEST_CANCELLED',
);

is(
    $cancel_server_tx->remote_stop_sending_code,
    0x10c,
    'server Transaction records remote STOP_SENDING H3_REQUEST_CANCELLED',
);

ok(
    !defined($cancel_server_tx->local_reset_code),
    'server Transaction does not mislabel peer STOP_SENDING as an explicit local reset',
);

is(
    $cancel_client_tx->remote_reset_code,
    0x10c,
    'client Transaction records remote RESET_STREAM H3_REQUEST_CANCELLED',
);

ok($cancel_client_tx->is_aborted,
    'client Transaction records request-stream abort state');
ok($cancel_server_tx->is_aborted,
    'server Transaction records request-stream abort state');
ok($cancel_client_tx->is_cancelled, 'client Transaction is cancelled');
ok($cancel_server_tx->is_cancelled, 'server Transaction is cancelled');
ok(!$received_cancel_response->is_complete,
    'cancelled response is not reported as complete');

is(
    $server_h3->max_buffered_body_bytes,
    1024,
    'server uses configured buffered body limit',
);

my $malformed_stream = $client_quic->open_bidi_stream;
ok(defined($malformed_stream),
    'client opens raw stream for malformed request regression');

$client_h3->{streams}{ $malformed_stream->id } = $malformed_stream;

$client_h3->{native}->submit_request(
    $malformed_stream->id,
    [
        [ ':method',    'GET' ],
        [ ':scheme',    'https' ],
        [ ':authority', 'localhost' ],
        [ ':path',      '/bad-host' ],
        [ 'host',       'other.example' ],
    ],
    undef,
    0,
);

$client_h3->_drain_output;

ok(
    run_until(sub {
        return defined($malformed_stream->remote_reset_code);
    }),
    'malformed Host/:authority request is reset by the server',
);

is(
    $malformed_stream->remote_reset_code,
    0x10e,
    'malformed request stream is reset with H3_MESSAGE_ERROR',
);

ok(!$server_h3->failed,
    'malformed request does not fail the HTTP/3 connection');

is(
    $server_h3->next_transaction,
    undef,
    'malformed request is not exposed as an application Transaction',
);

my $after_malformed_request = Uniform::HTTP::Request->new(
    method    => 'GET',
    target    => '/after-malformed',
    scheme    => 'https',
    authority => 'localhost',
);

my $after_malformed_client_tx =
    $client_h3->request($after_malformed_request);
my $after_malformed_server_tx;

ok(
    run_until(sub {
        $after_malformed_server_tx ||= $server_h3->next_transaction;
        return defined $after_malformed_server_tx;
    }),
    'server accepts another request after malformed stream rejection',
);

$after_malformed_server_tx->send_response;

ok(
    run_until(sub {
        return $after_malformed_client_tx->is_complete
            && $after_malformed_server_tx->is_complete;
    }),
    'connection remains usable after H3_MESSAGE_ERROR stream reset',
);

my $oversized_request = Uniform::HTTP::Request->new(
    method    => 'POST',
    target    => '/too-large',
    scheme    => 'https',
    authority => 'localhost',
    body      => 'z' x 2048,
);

my $oversized_tx = $client_h3->request($oversized_request);
isa_ok($oversized_tx, ['Unblock::HTTP3::Transaction']);

ok(
    run_until(sub {
        return $server_h3->failed;
    }),
    'server rejects a body larger than its configured buffer limit',
);

is(
    $server_h3->error_code,
    0x0107,
    'body limit closes HTTP/3 with H3_EXCESSIVE_LOAD',
);

like(
    $server_h3->error,
    qr/buffered body exceeds configured limit/,
    'body limit records a useful HTTP/3 error',
);

close $client_socket;
close $server_socket;

done_testing;