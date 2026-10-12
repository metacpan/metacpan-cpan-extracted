use strict;
use warnings;

use Scalar::Util qw(refaddr);
use Test2::V0;

use Uniform::HTTP::Request;
use Uniform::HTTP::Response;
use Unblock::HTTP3::Client;
use Unblock::HTTP3::Connection;
use Unblock::HTTP3::NativeABI;
use Unblock::HTTP3::Transaction;
use Unblock::HTTP3::_Native;

my $definition = Unblock::HTTP3::NativeABI::definition();

is(
    $definition->{abi_version},
    Unblock::HTTP3::NativeABI::ABI_VERSION(),
    'native consumer ABI reports version 1',
);

ok(
    $definition->{operations_address},
    'native consumer ABI exposes an operations address',
);

is(
    $definition->{struct_size},
    Unblock::HTTP3::_Native::_consumer_operations_size(),
    'native consumer ABI reports the provider structure size',
);

ok(
    -f Unblock::HTTP3::NativeABI::header_path(),
    'native consumer ABI header is installed',
);

like(
    Unblock::HTTP3::NativeABI::c_header(),
    qr/ub_http3_consumer_ops_v1/,
    'native consumer ABI publishes its C operations layout',
);

like(
    Unblock::HTTP3::NativeABI::c_header(),
    qr/transaction_request/,
    'native ABI exposes direct canonical request access',
);

like(
    Unblock::HTTP3::NativeABI::c_header(),
    qr/\(\*respond\)\s*\(/,
    'native ABI uses the common respond vocabulary',
);
unlike(
    Unblock::HTTP3::NativeABI::c_header(),
    qr/\(\*send_response\)\s*\(/,
    'native ABI does not retain the old send_response name',
);

my $fake_connection = bless {}, 'Unblock::HTTP3::Client';

ok(
    Unblock::HTTP3::_Native::_consumer_context_probe(
        $fake_connection,
    ),
    'native provider can create and destroy a persistent Connection context',
);

my $request = Uniform::HTTP::Request->new(
    method    => 'GET',
    target    => '/native-abi',
    scheme    => 'https',
    authority => 'example.test',
);

my $response = Uniform::HTTP::Response->new(
    status => 200,
);

my $informational = Uniform::HTTP::Response->new(
    status => 103,
);

my $transaction = bless {
    stream_id     => 12,
    state         => 'active',
    request       => $request,
    response      => $response,
    informational => [ $informational ],
}, 'Unblock::HTTP3::Transaction';

my $probe =
    Unblock::HTTP3::_Native::_consumer_transaction_probe(
        $transaction,
    );

is($probe->[0], 12, 'native ABI reads Transaction stream ID');
is(
    $probe->[1],
    Unblock::HTTP3::NativeABI::TX_ACTIVE(),
    'native ABI maps Transaction state',
);
is(
    refaddr($probe->[2]),
    refaddr($request),
    'native ABI exposes the canonical Request',
);
is(
    refaddr($probe->[3]),
    refaddr($response),
    'native ABI exposes the canonical Response',
);
is(
    refaddr($probe->[4]),
    refaddr($informational),
    'native ABI polls canonical informational responses',
);

my $queue_connection = bless {
    started             => 0,
    failed              => 1,
    error_code          => 0x0101,
    error               => 'native ABI test failure',
    ready_transactions  => [ $transaction ],
    ready_informational => [ $transaction ],
}, 'Unblock::HTTP3::Client';

my $queue_probe =
    Unblock::HTTP3::_Native::_consumer_queue_probe(
        $queue_connection,
    );

is(
    refaddr($queue_probe->[0]),
    refaddr($transaction),
    'native ABI polls ready Transactions from the Connection queue',
);
is(
    refaddr($queue_probe->[1]),
    refaddr($transaction),
    'native ABI polls informational Transaction events',
);
is($queue_probe->[2], 1, 'native ABI exposes Connection failure state');
is($queue_probe->[3], 1, 'native ABI reports an available HTTP/3 error code');
is($queue_probe->[4], 0x0101, 'native ABI preserves the HTTP/3 error code');
is(
    $queue_probe->[5],
    'native ABI test failure',
    'native ABI exposes the Connection error message',
);

done_testing;
