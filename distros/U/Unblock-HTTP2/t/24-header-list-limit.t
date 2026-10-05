use strict;
use warnings;
use Test::More;
use lib 't/lib';

use Test::UnblockHTTP2 qw(pump_until);
use Uniform::HTTP::Request;
use Uniform::HTTP::Response;
use Unblock::HTTP2::Client;
use Unblock::HTTP2::Server;

my @server_errors;
my @bad_errors;
my @good_errors;
my $good_body = '';
my $good_complete = 0;

my $server = Unblock::HTTP2::Server->new(
    max_header_list_size => 256,

    on_request => sub {
        my ($stream, $request) = @_;

        if ($request->target eq '/good') {
            $stream->respond(
                Uniform::HTTP::Response->new(
                    status => 200,
                    body   => 'good',
                ),
            );
        }
    },

    on_error => sub {
        my ($stream, $error) = @_;
        push @server_errors, $error;
    },
);

my $client = Unblock::HTTP2::Client->new;

my $bad_request = Uniform::HTTP::Request->new(
    method    => 'GET',
    target    => '/bad',
    scheme    => 'https',
    authority => 'example.test',
    headers   => [ [ 'x-oversized', 'x' x 300 ] ],
);

my $bad = $client->request(
    $bad_request,
    on_error => sub {
        my ($stream, $error) = @_;
        push @bad_errors, $error;
    },
);

my $good_request = Uniform::HTTP::Request->new(
    method    => 'GET',
    target    => '/good',
    scheme    => 'https',
    authority => 'example.test',
);

my $good = $client->request(
    $good_request,

    on_body => sub {
        my ($stream, $response, $bytes) = @_;
        $good_body .= $bytes;
    },

    on_complete => sub {
        $good_complete = 1;
    },

    on_error => sub {
        my ($stream, $error) = @_;
        push @good_errors, $error;
    },
);

pump_until(
    $client,
    $server,
    sub { $good_complete && @bad_errors },
);

ok $bad->is_terminal, 'oversized header stream is terminal';
like $bad->error || '', qr/stream closed with error/,
    'client sees a stream-local reset for oversized headers';

ok $good->is_complete, 'neighbor stream completes normally';
is $good_body, 'good', 'neighbor stream body is intact';
is_deeply \@good_errors, [], 'neighbor stream has no error';
ok !$client->is_closed, 'header-list violation does not close the connection';

ok @server_errors >= 1, 'server reports the rejected header block';
like $server_errors[0], qr/header list exceeds configured limit/,
    'server reports the configured header-list limit';

done_testing;
