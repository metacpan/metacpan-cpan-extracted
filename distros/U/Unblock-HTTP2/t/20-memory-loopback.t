use strict;
use warnings;
use Test::More;

use Uniform::HTTP::Request;
use Uniform::HTTP::Response;
use Unblock::HTTP2::Client;
use Unblock::HTTP2::Server;

my %seen = (
    server_body => '',
    client_body => '',
    server_errors => [],
    client_errors => [],
);

my $server = Unblock::HTTP2::Server->new(
    on_request => sub {
        my ($stream, $request) = @_;

        is $request->method, 'POST', 'server receives method';
        is $request->target, '/echo', 'server receives target';
        is $request->scheme, 'https', 'server receives scheme';
        is $request->authority, 'example.test',
            'server receives authority';
        ok !$request->initial_is_mutable,
            'server request initial metadata is frozen';
        ok $request->trailers_are_mutable,
            'server request can still acquire trailers before completion';
        ok !$request->is_complete,
            'server sees request as incomplete before DATA finishes';
    },

    on_body => sub {
        my ($stream, $request, $bytes) = @_;
        $seen{server_body} .= $bytes;
    },

    on_request_end => sub {
        my ($stream, $request) = @_;

        ok $request->is_complete,
            'server request becomes complete at END_STREAM';

        my $response = Uniform::HTTP::Response->new(
            status  => 200,
            headers => [
                [ 'Content-Type', 'text/plain' ],
                [ 'X-Reply',      'memory-loopback' ],
            ],
            body => 'pong',
        );

        $stream->respond($response);
        ok $response->initial_is_mutable,
            'submitted application response remains application-owned';
        is $response->version, undef,
            'server submission does not stamp HTTP version onto application response';
    },

    on_error => sub {
        my ($stream, $error) = @_;
        push @{ $seen{server_errors} }, $error;
    },
);

my $client = Unblock::HTTP2::Client->new;

my $request = Uniform::HTTP::Request->new(
    method    => 'POST',
    target    => '/echo',
    scheme    => 'https',
    authority => 'example.test',
    headers   => [
        [ 'Content-Type', 'text/plain' ],
        [ 'X-Test',       'one' ],
        [ 'X-Test',       'two' ],
    ],
    body => 'ping',
);

my $complete = 0;
my $stream = $client->request(
    $request,

    on_response => sub {
        my ($stream, $response) = @_;

        is $response->status, 200, 'client receives response status';
        is $response->header('content-type'), 'text/plain',
            'client receives response headers';
        is $response->header('x-reply'), 'memory-loopback',
            'client receives custom response header';
        ok !$response->initial_is_mutable,
            'client response initial metadata is frozen';
        ok $response->trailers_are_mutable,
            'client response can still acquire trailers before completion';
        ok !$response->is_complete,
            'client sees response as incomplete before DATA finishes';
    },

    on_body => sub {
        my ($stream, $response, $bytes) = @_;
        $seen{client_body} .= $bytes;
    },

    on_complete => sub {
        my ($stream) = @_;
        $complete = 1;
        ok $stream->response->is_complete,
            'client response becomes complete at END_STREAM';
    },

    on_error => sub {
        my ($stream, $error) = @_;
        push @{ $seen{client_errors} }, $error;
    },
);

ok $request->initial_is_mutable,
    'submitted client request remains application-owned';
is $request->version, undef,
    'client submission leaves application request version neutral';

sub transfer {
    my ($from, $to) = @_;
    my $moved = 0;

    while ($from->want_write) {
        my $bytes = $from->output;
        last unless length $bytes;
        $to->input($bytes);
        $moved += length $bytes;
    }

    return $moved;
}

for (1 .. 1000) {
    my $moved = 0;
    $moved += transfer($client, $server);
    $moved += transfer($server, $client);

    last if $complete;
    die "in-memory HTTP/2 loopback stalled"
        unless $moved;
}

ok $complete, 'in-memory HTTP/2 exchange completes';
is $seen{server_body}, 'ping', 'server receives complete request body';
is $seen{client_body}, 'pong', 'client receives complete response body';
is_deeply $seen{server_errors}, [], 'server reports no errors';
is_deeply $seen{client_errors}, [], 'client reports no errors';
ok $stream->is_complete, 'client stream is complete';

done_testing;
