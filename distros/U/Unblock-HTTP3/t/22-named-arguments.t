use strict;
use warnings;

use Test2::V0;
use Scalar::Util qw(refaddr);

use Uniform::HTTP::Request;
use Uniform::HTTP::Response;
use Unblock::HTTP3::Client;
use Unblock::HTTP3::Server;
use Unblock::HTTP3::Transaction;

my ($captured_request, $captured_request_options);
my $client = bless {}, 'Unblock::HTTP3::Client';

{
    no warnings 'redefine';
    local *Unblock::HTTP3::Connection::request = sub {
        my ($self, $request, %options) = @_;
        $captured_request = $request;
        $captured_request_options = \%options;
        return 'submitted';
    };

    is(
        $client->request(
            method => 'GET', target => '/', scheme => 'https',
            authority => 'example.test', on_response => sub {},
            receive_body => 'stream', early_data => 0, datagrams => 0,
        ),
        'submitted',
        'named request fields are accepted',
    );
    isa_ok($captured_request, ['Uniform::HTTP::Request']);
    is($captured_request->method, 'GET', 'named request builds Uniform request');
    is($captured_request->authority, 'example.test', 'authority is preserved');
    is($captured_request_options->{receive_body}, 'stream',
        'receive_body remains an HTTP/3 option');
    ok(ref($captured_request_options->{on_response}) eq 'CODE',
        'on_response remains a callback option');

    my $object = Uniform::HTTP::Request->new(
        method => 'GET', target => '/', scheme => 'https',
        authority => 'example.test',
    );
    $client->request($object, stream_body => 0);
    is(refaddr($captured_request), refaddr($object),
        'request object retains its identity');

    like(
        dies { $client->request(method => 'GET', 'target') },
        qr/key\/value pairs/,
        'odd request fields are rejected',
    );
    like(
        dies { $client->request($object, 'on_response') },
        qr/key\/value pairs/,
        'odd request object options are rejected',
    );
}

my $server = bless {}, 'Unblock::HTTP3::Server';
my $request = Uniform::HTTP::Request->new(method => 'GET', target => '/');
my $transaction = Unblock::HTTP3::Transaction->_new(
    connection => $server, stream_id => 0, request => $request,
);
my ($captured_response, $captured_response_options, $captured_informational);

{
    no warnings 'redefine';
    local *Unblock::HTTP3::Connection::_respond_transaction = sub {
        my ($connection, $tx, $response, %options) = @_;
        $captured_response = $response;
        $captured_response_options = \%options;
        return $tx;
    };
    local *Unblock::HTTP3::Connection::_send_informational_response = sub {
        my ($connection, $tx, $response) = @_;
        $captured_informational = $response;
    };

    is($transaction->respond(status => 200, body => 'hello'), $transaction,
        'named response fields return transaction');
    isa_ok($captured_response, ['Uniform::HTTP::Response']);
    is($captured_response->status, 200, 'named response status is preserved');
    is($captured_response->body, 'hello', 'named response body is preserved');

    $transaction->respond(status => 201, stream_body => 1, on_drain => sub {});
    is($captured_response->status, 201, 'second named response is built');
    is($captured_response_options->{stream_body}, 1,
        'stream_body is passed to engine, not Uniform Response');
    ok(ref($captured_response_options->{on_drain}) eq 'CODE',
        'on_drain remains a response option');

    my $object = Uniform::HTTP::Response->new(status => 204);
    $transaction->respond($object);
    is(refaddr($captured_response), refaddr($object),
        'response object retains identity');

    is($transaction->send_informational(status => 103), $transaction,
        'named informational response fields are accepted');
    isa_ok($captured_informational, ['Uniform::HTTP::Response']);
    is($captured_informational->status, 103,
        'named informational status is preserved');

    my $early = Uniform::HTTP::Response->new(status => 102);
    $transaction->send_informational($early);
    is(refaddr($captured_informational), refaddr($early),
        'informational response object retains identity');

    like(dies { $transaction->respond(status => 200, 'body') },
        qr/key\/value pairs/, 'odd named response fields are rejected');
    like(dies { $transaction->send_informational(status => 103, 'body') },
        qr/key\/value pairs/, 'odd informational fields are rejected');
    like(dies { $transaction->send_informational($early, on_drain => sub {}) },
        qr/does not take options/, 'informational object options are rejected');
    like(dies { $transaction->send_informational(status => 101) },
        qr/status must be 100 through 199/, 'HTTP/3 still rejects 101');
}

done_testing;
