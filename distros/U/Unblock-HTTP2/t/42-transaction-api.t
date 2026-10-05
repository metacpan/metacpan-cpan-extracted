use strict;
use warnings;
use Test::More;
use lib 't/lib';

use Test::UnblockHTTP2 qw(pump_until);
use Uniform::HTTP::Request;
use Uniform::HTTP::Response;
use Unblock::HTTP2::Client;
use Unblock::HTTP2::Server;
use Unblock::HTTP2::Transaction;

my $server_transaction;

my $server = Unblock::HTTP2::Server->new(
    on_request => sub {
        my ($transaction, $request) = @_;
        $server_transaction = $transaction;

        $transaction->respond(
            Uniform::HTTP::Response->new(
                status => 200,
                body   => 'ok',
            ),
        );
    },
);

my $client = Unblock::HTTP2::Client->new;

ok $client->can_open_transaction,
    'client exposes transaction-oriented capacity API';
my $transaction = $client->request(
    Uniform::HTTP::Request->new(
        method    => 'GET',
        target    => '/transaction',
        scheme    => 'https',
        authority => 'example.test',
    ),
);

isa_ok $transaction, 'Unblock::HTTP2::Transaction';
ok $transaction->can('send_informational'),
    'transaction exposes the common send_informational method';
ok !$transaction->can('inform'),
    'removed inform method is not kept as a compatibility alias';
ok $transaction->can('is_error'),
    'transaction exposes the common is_error state predicate';
ok !$transaction->is_error,
    'active transaction is not in error state';
is $transaction->stream_id, 1,
    'transaction exposes its HTTP/2 stream id';
is $client->transaction_count, 1,
    'connection exposes active transaction count';
is $client->transaction_for_stream_id($transaction->stream_id), $transaction,
    'transaction can be looked up by protocol stream id';
pump_until(
    $client,
    $server,
    sub { $transaction->is_complete && $server_transaction },
);

isa_ok $server_transaction, 'Unblock::HTTP2::Transaction';
is $server_transaction->stream_id, $transaction->stream_id,
    'client and server transactions refer to the same HTTP/2 stream';
ok !$transaction->is_error,
    'completed client transaction did not enter error state';
ok !$server_transaction->is_error,
    'completed server transaction did not enter error state';

done_testing;
