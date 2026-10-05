use strict;
use warnings;
use Test::More;
use lib 't/lib';

use Test::UnblockHTTP2 qw(pump_until);
use Uniform::HTTP::Request;
use Uniform::HTTP::Response;
use Unblock::HTTP2::Client;
use Unblock::HTTP2::Server;

my %server_stream;
my @server_errors;
my @client_errors;
my $keep_body = '';
my $keep_complete = 0;

my $server = Unblock::HTTP2::Server->new(
    on_request => sub {
        my ($stream, $request) = @_;
        $server_stream{ $request->target } = $stream;
    },

    on_error => sub {
        my ($stream, $error) = @_;
        push @server_errors, $error;
    },
);

my $client = Unblock::HTTP2::Client->new;

sub request_for {
    my ($target) = @_;
    return Uniform::HTTP::Request->new(
        method    => 'GET',
        target    => $target,
        scheme    => 'https',
        authority => 'example.test',
    );
}

my $cancel = $client->request(
    request_for('/cancel'),
    on_error => sub {
        my ($stream, $error) = @_;
        push @client_errors, "cancel: $error";
    },
);

my $keep = $client->request(
    request_for('/keep'),

    on_body => sub {
        my ($stream, $response, $bytes) = @_;
        $keep_body .= $bytes;
    },

    on_complete => sub {
        $keep_complete = 1;
    },

    on_error => sub {
        my ($stream, $error) = @_;
        push @client_errors, "keep: $error";
    },
);

pump_until(
    $client,
    $server,
    sub {
        return $server_stream{'/cancel'} && $server_stream{'/keep'};
    },
);

ok !$client->is_closed, 'connection remains open with two active streams';

$cancel->cancel;
ok $cancel->is_cancelled, 'client cancellation is immediately visible locally';

$server_stream{'/keep'}->respond(
    Uniform::HTTP::Response->new(
        status => 200,
        body   => 'still-alive',
    ),
);

pump_until($client, $server, sub { $keep_complete });

ok $keep->is_complete, 'neighbor stream completes after cancellation';
is $keep_body, 'still-alive', 'neighbor response body is intact';
ok !$client->is_closed, 'cancelling one stream does not close the connection';
ok $server_stream{'/cancel'}->is_terminal,
    'server observes the cancelled peer stream as terminal';
is_deeply \@client_errors, [],
    'local cancellation does not become a client error callback';
ok @server_errors >= 1,
    'server is notified that the peer reset the cancelled stream';

done_testing;
