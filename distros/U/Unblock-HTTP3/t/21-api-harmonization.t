use strict;
use warnings;

use Scalar::Util qw(refaddr);
use Test2::V0;

use Uniform::HTTP::Request;
use Uniform::HTTP::Response;
use Unblock::HTTP3::_Native;
use Unblock::HTTP3::Client;
use Unblock::HTTP3::Connection;
use Unblock::HTTP3::NativeABI;
use Unblock::HTTP3::Server;
use Unblock::HTTP3::Transaction;

ok(Unblock::HTTP3::Client->can('new'), 'Client has new()');
ok(Unblock::HTTP3::Server->can('new'), 'Server has new()');

ok(!Unblock::HTTP3::Connection->can('client'),
    'legacy Connection->client() is removed');
ok(!Unblock::HTTP3::Connection->can('server'),
    'legacy Connection->server() is removed');

for my $method (qw(
    state error is_complete is_cancelled is_error is_terminal
    respond write end send_informational
)) {
    ok(Unblock::HTTP3::Transaction->can($method),
        "Transaction has $method()");
}

ok(!Unblock::HTTP3::Transaction->can('send_response'),
    'legacy send_response() is removed');

{
    package Local::HTTP3UniformRequest;
    use parent 'Uniform::HTTP::Request';
}

{
    package Local::HTTP3UniformResponse;
    use parent 'Uniform::HTTP::Response';
}

my $portable_request = Local::HTTP3UniformRequest->new(
    method    => 'GET',
    target    => '/portable',
    scheme    => 'https',
    authority => 'example.test',
);

ok(
    Unblock::HTTP3::Connection::_request_contract($portable_request),
    'Uniform Request subclass satisfies the portable request contract',
);
is(
    Unblock::HTTP3::Connection::_portable_request_fields($portable_request),
    [
        [ ':method',    'GET' ],
        [ ':scheme',    'https' ],
        [ ':authority', 'example.test' ],
        [ ':path',      '/portable' ],
    ],
    'portable Request path builds HTTP/3 fields without the canonical native path',
);

my $portable_response = Local::HTTP3UniformResponse->new(
    status => 204,
);

ok(
    Unblock::HTTP3::Connection::_response_contract($portable_response),
    'Uniform Response subclass satisfies the portable response contract',
);
is(
    Unblock::HTTP3::Connection::_portable_response_fields($portable_response),
    [
        [ ':status', '204' ],
    ],
    'portable Response path builds HTTP/3 fields without the canonical native path',
);

my $fake_client = bless {
    started           => 0,
    role              => 'client',
    receive_body_mode => 'buffered',
}, 'Unblock::HTTP3::Client';

like(
    dies {
        $fake_client->request(
            Uniform::HTTP::Request->new(
                method    => 'POST',
                target    => '/',
                scheme    => 'https',
                authority => 'example.test',
            ),
            stream_body => {},
        );
    },
    qr/stream_body must be zero or one/,
    'common request stream_body option is strictly boolean',
);

my $fake_server = bless {
    role          => 'server',
    transactions  => {},
    response_sent => {},
}, 'Unblock::HTTP3::Server';

my $server_request = Uniform::HTTP::Request->new(
    method => 'GET',
    target => '/',
);

my $server_response = Uniform::HTTP::Response->new(
    status => 200,
);

my $fake_transaction = Unblock::HTTP3::Transaction->_new(
    connection => $fake_server,
    stream_id  => 4,
    request    => $server_request,
    response   => $server_response,
);
$fake_server->{transactions}{4} = $fake_transaction;

like(
    dies {
        $fake_transaction->respond(
            $server_response,
            stream_body => {},
        );
    },
    qr/stream_body must be zero or one/,
    'common response stream_body option is strictly boolean',
);

my $advanced_client = bless {
    role => 'client',
}, 'Unblock::HTTP3::Client';

my $advanced_request = Uniform::HTTP::Request->new(
    method    => 'POST',
    target    => '/advanced-body',
    scheme    => 'https',
    authority => 'example.test',
);

my $advanced_transaction = Unblock::HTTP3::Transaction->_new(
    connection        => $advanced_client,
    stream_id         => 8,
    request           => $advanced_request,
    request_streaming => 1,
);

my $advanced_body = $advanced_transaction->request_body(
    on_drain => sub { },
);

is(
    refaddr(
        $advanced_transaction->request_body(
            on_cancel => sub { },
        ),
    ),
    refaddr($advanced_body),
    'advanced Body::Stream callbacks can be configured after common stream_body setup',
);

ok(
    Unblock::HTTP3::_Native::_consumer_context_probe(
        bless({}, 'Unblock::HTTP3::Client'),
    ),
    'native ABI accepts exact Client objects',
);
ok(
    Unblock::HTTP3::_Native::_consumer_context_probe(
        bless({}, 'Unblock::HTTP3::Server'),
    ),
    'native ABI accepts exact Server objects',
);
like(
    dies {
        Unblock::HTTP3::_Native::_consumer_context_probe(
            bless({}, 'Unblock::HTTP3::Connection'),
        );
    },
    qr/requires exact class Unblock::HTTP3::Client or Unblock::HTTP3::Server/,
    'native ABI rejects the internal Connection class',
);

for my $method (qw(definition native_include_dir header_path c_header)) {
    ok(Unblock::HTTP3::NativeABI->can($method),
        "NativeABI has $method()");
}

my $definition = Unblock::HTTP3::NativeABI::definition();
ok(defined $definition->{provider}, 'NativeABI definition reports provider');
is($definition->{abi_version}, 1, 'NativeABI version remains 1');
ok($definition->{struct_size} > 0, 'NativeABI definition reports struct_size');
ok($definition->{operations_address},
    'NativeABI definition reports operations_address');

done_testing;
