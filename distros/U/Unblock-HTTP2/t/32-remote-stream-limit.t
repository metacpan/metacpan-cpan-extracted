use strict;
use warnings;
use Test::More;
use lib 't/lib';

use Test::UnblockHTTP2 qw(pump_until pump_until_idle);
use Uniform::HTTP::Request;
use Uniform::HTTP::Response;
use Unblock::HTTP2::Client;
use Unblock::HTTP2::Server;

sub request_for {
    my ($target) = @_;
    return Uniform::HTTP::Request->new(
        method    => 'GET',
        target    => $target,
        scheme    => 'https',
        authority => 'example.test',
    );
}

my @server_streams;
my @errors;

my $server = Unblock::HTTP2::Server->new(
    max_concurrent_streams => 1,

    on_request => sub {
        my ($stream, $request) = @_;
        push @server_streams, $stream;
    },

    on_error => sub {
        my ($stream, $error) = @_;
        push @errors, "server: $error";
    },
);

my $client = Unblock::HTTP2::Client->new(
    max_active_transactions => 10,
);

pump_until_idle($client, $server);

ok $client->can_open_transaction,
    'client can open a stream before reaching the peer limit';

my $first = $client->request(
    request_for('/one'),
    on_error => sub {
        my ($stream, $error) = @_;
        push @errors, "client: $error";
    },
);

ok !$client->can_open_transaction,
    'peer SETTINGS_MAX_CONCURRENT_STREAMS is stricter than local limit';

my $ok = eval {
    $client->request(request_for('/two'));
    1;
};
ok !$ok,
    'request refuses a stream beyond the peer-advertised limit';
like $@, qr/cannot accept another transaction/,
    'peer stream-limit refusal uses the normal capacity error';

pump_until($client, $server, sub { @server_streams == 1 });

$server_streams[0]->respond(
    Uniform::HTTP::Response->new(
        status => 200,
        body   => 'done',
    ),
);

pump_until($client, $server, sub { $first->is_terminal });

ok $first->is_complete,
    'first stream completes normally';
ok $client->can_open_transaction,
    'capacity returns after the peer-limited stream closes';
is_deeply \@errors, [],
    'remote stream-limit handling reports no protocol errors';

done_testing;
