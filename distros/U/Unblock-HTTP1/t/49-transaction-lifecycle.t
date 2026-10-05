use strict;
use warnings;
use Test::More;

use Uniform::HTTP::Request;
use Unblock::HTTP1::Client;

my $client = Unblock::HTTP1::Client->new;
my $tx = $client->request(
    Uniform::HTTP::Request->new(
        method    => 'GET',
        target    => '/',
        authority => 'example.test',
    ),
);

is $tx->state, 'active', 'new transaction is active';
is $tx->error, undef, 'active transaction has no error';
ok !$tx->is_complete, 'active transaction is not complete';
ok !$tx->is_cancelled, 'active transaction is not cancelled';
ok !$tx->is_error, 'active transaction is not an error';
ok !$tx->is_terminal, 'active transaction is not terminal';

$client->output;
$client->input_eof;

is $tx->state, 'error', 'unexpected EOF moves transaction to error';
like $tx->error, qr/unexpected EOF in HTTP\/1 response/,
    'error accessor exposes the stored failure';
ok $tx->is_error, 'failed transaction reports is_error';
ok $tx->is_terminal, 'failed transaction is terminal';
ok !$tx->is_complete, 'failed transaction is not complete';
ok !$tx->is_cancelled, 'failed transaction is not cancelled';

my $cancel_client = Unblock::HTTP1::Client->new;
my $cancel_tx = $cancel_client->request(
    Uniform::HTTP::Request->new(
        method    => 'GET',
        target    => '/cancel',
        authority => 'example.test',
    ),
);

$cancel_tx->cancel;

is $cancel_tx->state, 'cancelled', 'cancel moves transaction to cancelled';
is $cancel_tx->error, undef, 'cancellation does not manufacture an error';
ok $cancel_tx->is_cancelled, 'cancelled transaction reports is_cancelled';
ok $cancel_tx->is_terminal, 'cancelled transaction is terminal';
ok !$cancel_tx->is_error, 'cancelled transaction is not an error';

done_testing;
