use strict;
use warnings;
use Test::More;
use lib 't/lib';

use Test::UnblockHTTP2 qw(pump_until);
use Uniform::HTTP::Request;
use Uniform::HTTP::Response;
use Unblock::HTTP2::Client;
use Unblock::HTTP2::Server;

my $server_body = '';
my $request_end = 0;
my @errors;

my $server = Unblock::HTTP2::Server->new(
    on_request => sub {
        my ($stream, $request) = @_;

        # Finish the response immediately while the peer's request body
        # remains open.
        $stream->respond(
            Uniform::HTTP::Response->new(
                status => 200,
                body   => 'early-response',
            ),
        );
    },

    on_body => sub {
        my ($stream, $request, $bytes) = @_;
        $server_body .= $bytes;
    },

    on_request_end => sub {
        $request_end = 1;
    },

    on_error => sub {
        my ($stream, $error) = @_;
        push @errors, "server: $error";
    },
);

my $client = Unblock::HTTP2::Client->new;
my $response_body = '';
my $response_complete = 0;
my $terminal_in_response_callback;

my $stream = $client->request(
    Uniform::HTTP::Request->new(
        method    => 'POST',
        target    => '/half-close',
        scheme    => 'https',
        authority => 'example.test',
    ),
    stream_body => 1,

    on_body => sub {
        my ($stream, $response, $bytes) = @_;
        $response_body .= $bytes;
    },

    on_complete => sub {
        my ($stream) = @_;
        $terminal_in_response_callback = $stream->is_terminal;
        $response_complete = 1;
    },

    on_error => sub {
        my ($stream, $error) = @_;
        push @errors, "client: $error";
    },
);

pump_until($client, $server, sub { $response_complete });

is $response_body, 'early-response',
    'client receives complete response while request producer is still open';
ok !$terminal_in_response_callback,
    'response completion does not make a half-open HTTP/2 stream terminal';
ok !$stream->is_terminal,
    'stream remains active after remote response half closes';

is $stream->write('late-request-body'), 1,
    'client can continue writing request DATA after response completion';
$stream->end;

pump_until(
    $client,
    $server,
    sub { $request_end && $stream->is_terminal },
);

is $server_body, 'late-request-body',
    'server receives request DATA sent after its response completed';
ok $stream->is_complete,
    'stream becomes terminal only after both HTTP/2 halves finish';
is_deeply \@errors, [],
    'half-close lifecycle reports no errors';

done_testing;
