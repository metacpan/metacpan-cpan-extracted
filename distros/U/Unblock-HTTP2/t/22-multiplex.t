use strict;
use warnings;
use Test::More;
use lib 't/lib';

use Test::UnblockHTTP2 qw(pump_until);
use Uniform::HTTP::Request;
use Uniform::HTTP::Response;
use Unblock::HTTP2::Client;
use Unblock::HTTP2::Server;

my %server_seen;
my %body;
my @errors;

my $server = Unblock::HTTP2::Server->new(
    on_request => sub {
        my ($stream, $request) = @_;

        ++$server_seen{ $request->target };

        my $response = Uniform::HTTP::Response->new(
            status => 200,
            body   => 'response:' . $request->target,
        );

        $stream->respond($response);
    },

    on_error => sub {
        my ($stream, $error) = @_;
        push @errors, "server: $error";
    },
);

my $client = Unblock::HTTP2::Client->new;

my $complete = 0;
my @streams;

for my $target ('/one', '/two', '/three') {
    my $path = $target;

    my $request = Uniform::HTTP::Request->new(
        method    => 'GET',
        target    => $path,
        scheme    => 'https',
        authority => 'example.test',
    );

    my $stream = $client->request(
        $request,

        on_body => sub {
            my ($stream, $response, $bytes) = @_;
            $body{$path} .= $bytes;
        },

        on_complete => sub {
            ++$complete;
        },

        on_error => sub {
            my ($stream, $error) = @_;
            push @errors, "client $path: $error";
        },
    );

    push @streams, $stream;
}

is $client->transaction_count, 3,
    'three client transactions are active before transport pumping';
is_deeply [ map { $_->stream_id } @streams ], [ 1, 3, 5 ],
    'client transactions expose independent HTTP/2 stream ids';

pump_until($client, $server, sub { $complete == 3 });

is_deeply \%server_seen,
    { '/one' => 1, '/two' => 1, '/three' => 1 },
    'server receives all multiplexed requests';

is $body{'/one'}, 'response:/one', 'first response body is isolated';
is $body{'/two'}, 'response:/two', 'second response body is isolated';
is $body{'/three'}, 'response:/three', 'third response body is isolated';

ok $_->is_complete, 'multiplexed stream completed' for @streams;
is_deeply \@errors, [], 'multiplexed connection reports no errors';

done_testing;
