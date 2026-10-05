use strict;
use warnings;
use Test::More;
use lib 't/lib';

use Test::UnblockHTTP2 qw(pump_until pump_until_idle);
use Uniform::HTTP::Request;
use Uniform::HTTP::Response;
use Unblock::HTTP2::Client;
use Unblock::HTTP2::Server;

my @errors;
my $slow_server_stream;
my %request_bytes;
my %request_complete;

my $server = Unblock::HTTP2::Server->new(
    on_request => sub {
        my ($stream, $request) = @_;

        if ($request->target eq '/slow-request') {
            $slow_server_stream = $stream;
            $stream->auto_consume(0);
        }
    },

    on_body => sub {
        my ($stream, $request, $bytes) = @_;
        $request_bytes{ $request->target } += length $bytes;
    },

    on_request_end => sub {
        my ($stream, $request) = @_;
        ++$request_complete{ $request->target };

        $stream->respond(
            Uniform::HTTP::Response->new(
                status => 200,
                body   => 'ok',
            ),
        );
    },

    on_error => sub {
        my ($stream, $error) = @_;
        push @errors, "server request: $error";
    },
);

my $client = Unblock::HTTP2::Client->new;
pump_until_idle($client, $server);

$server->update_settings(
    initial_window_size => 1024,
);
pump_until_idle($client, $server);

my %client_complete;

my $slow_request = $client->request(
    Uniform::HTTP::Request->new(
        method    => 'POST',
        target    => '/slow-request',
        scheme    => 'https',
        authority => 'example.test',
    ),
    stream_body => 1,
    on_complete => sub {
        ++$client_complete{'/slow-request'};
    },
    on_error => sub {
        my ($stream, $error) = @_;
        push @errors, "slow request client: $error";
    },
);

my $fast_request = $client->request(
    Uniform::HTTP::Request->new(
        method    => 'POST',
        target    => '/fast-request',
        scheme    => 'https',
        authority => 'example.test',
    ),
    stream_body => 1,
    on_complete => sub {
        ++$client_complete{'/fast-request'};
    },
    on_error => sub {
        my ($stream, $error) = @_;
        push @errors, "fast request client: $error";
    },
);

my $request_payload = 'r' x 4096;
$slow_request->write($request_payload);
$slow_request->end;
$fast_request->write($request_payload);
$fast_request->end;

pump_until(
    $client,
    $server,
    sub { $client_complete{'/fast-request'} },
);

ok $slow_server_stream, 'server created the slow request stream';
is $slow_server_stream->auto_consume, 0,
    'slow server stream uses manual receive consumption';
is $request_bytes{'/slow-request'}, 1024,
    'manual request stream stops at the deliberately small stream window';
is $slow_server_stream->unconsumed_bytes, 1024,
    'slow request bytes remain unconsumed';
is $request_bytes{'/fast-request'}, length($request_payload),
    'automatic request stream continues while the slow stream is blocked';
ok $request_complete{'/fast-request'},
    'fast request reaches END_STREAM independently';
ok !$request_complete{'/slow-request'},
    'slow request does not reach END_STREAM before receive credit is released';

my $overconsume_ok = eval {
    $slow_server_stream->consume(1025);
    1;
};
ok !$overconsume_ok, 'consume rejects credit beyond delivered bytes';
like $@, qr/cannot consume more bytes than have been delivered/,
    'over-consume failure is explicit';

$slow_server_stream->consume(512);
pump_until_idle($client, $server);

is $request_bytes{'/slow-request'}, 1536,
    'partial consume releases exactly that much additional request data';
is $slow_server_stream->unconsumed_bytes, 1024,
    'newly delivered bytes remain withheld after partial consume';

my $request_guard = 0;
while (!$client_complete{'/slow-request'} && ++$request_guard < 10) {
    my $pending = $slow_server_stream->unconsumed_bytes;
    last unless $pending;
    $slow_server_stream->consume($pending);
    pump_until_idle($client, $server);
}

ok $client_complete{'/slow-request'},
    'manual request stream completes as the application releases credit';
is $request_bytes{'/slow-request'}, length($request_payload),
    'manual request flow control preserves the complete body';

my $slow_client_stream;
my %response_bytes;
my %response_complete;

my $response_server = Unblock::HTTP2::Server->new(
    on_request => sub {
        my ($stream, $request) = @_;

        $stream->respond(
            Uniform::HTTP::Response->new(
                status => 200,
                body   => 's' x 4096,
            ),
        );
    },

    on_error => sub {
        my ($stream, $error) = @_;
        push @errors, "response server: $error";
    },
);

my $response_client = Unblock::HTTP2::Client->new;
pump_until_idle($response_client, $response_server);

$response_client->update_settings(
    initial_window_size => 1024,
);
pump_until_idle($response_client, $response_server);

$slow_client_stream = $response_client->request(
    Uniform::HTTP::Request->new(
        method    => 'GET',
        target    => '/slow-response',
        scheme    => 'https',
        authority => 'example.test',
    ),
    on_body => sub {
        my ($stream, $response, $bytes) = @_;
        $response_bytes{'/slow-response'} += length $bytes;
    },
    on_complete => sub {
        ++$response_complete{'/slow-response'};
    },
    on_error => sub {
        my ($stream, $error) = @_;
        push @errors, "slow response client: $error";
    },
);
$slow_client_stream->auto_consume(0);

my $fast_client_stream = $response_client->request(
    Uniform::HTTP::Request->new(
        method    => 'GET',
        target    => '/fast-response',
        scheme    => 'https',
        authority => 'example.test',
    ),
    on_body => sub {
        my ($stream, $response, $bytes) = @_;
        $response_bytes{'/fast-response'} += length $bytes;
    },
    on_complete => sub {
        ++$response_complete{'/fast-response'};
    },
    on_error => sub {
        my ($stream, $error) = @_;
        push @errors, "fast response client: $error";
    },
);

pump_until(
    $response_client,
    $response_server,
    sub { $response_complete{'/fast-response'} },
);

is $slow_client_stream->auto_consume, 0,
    'slow client stream uses manual response consumption';
is $response_bytes{'/slow-response'}, 1024,
    'manual response stream stops at the small stream window';
is $slow_client_stream->unconsumed_bytes, 1024,
    'slow response bytes remain unconsumed';
is $response_bytes{'/fast-response'}, 4096,
    'fast response is not stalled by the slow response stream';
ok $response_complete{'/fast-response'},
    'fast response completes independently';
ok !$response_complete{'/slow-response'},
    'slow response remains flow-control blocked';

$slow_client_stream->consume(512);
pump_until_idle($response_client, $response_server);

is $response_bytes{'/slow-response'}, 1536,
    'partial response consume releases exactly that much more data';
is $slow_client_stream->unconsumed_bytes, 1024,
    'response accounting remains bounded by the stream window';

$slow_client_stream->auto_consume(1);
pump_until(
    $response_client,
    $response_server,
    sub { $response_complete{'/slow-response'} },
);

is $response_bytes{'/slow-response'}, 4096,
    're-enabling auto consume releases pending credit and finishes the response';
is $slow_client_stream->unconsumed_bytes, 0,
    'automatic consumption leaves no outstanding response bytes';
ok $slow_client_stream->auto_consume,
    'auto consumption can be re-enabled per stream';

is_deeply \@errors, [],
    'receive flow-control tests report no protocol errors';

done_testing;
