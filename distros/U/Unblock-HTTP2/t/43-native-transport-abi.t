use strict;
use warnings;
use Test::More;

use Uniform::HTTP::Request;
use Uniform::HTTP::Response;
use Unblock::HTTP2::Client;
use Unblock::HTTP2::NativeABI;
use Unblock::HTTP2::Server;
use Unblock::HTTP2::_nghttp2;

my $definition = Unblock::HTTP2::NativeABI::definition();
is $definition->{abi_version}, 1, 'native transport ABI version is 1';
ok $definition->{struct_size},
    'native transport ABI exposes its structure size';
ok $definition->{operations_address},
    'native transport ABI exposes operations table';

my $include_dir = Unblock::HTTP2::NativeABI::native_include_dir();
ok -d $include_dir, 'native transport ABI exposes an installed include directory';
my $header_path = Unblock::HTTP2::NativeABI::header_path();
ok -f $header_path, 'native transport ABI exposes an installed header path';

my $header = Unblock::HTTP2::NativeABI::c_header();
like $header,
    qr/ub_http2_native_ops_v1/,
    'native transport ABI publishes its C layout';
like $header,
    qr/ub_http2_output_sink_v1/,
    'native transport ABI publishes the output sink contract';
my @common_order = map { index($header, $_) }
    ('void *(*create)', 'int (*input)', 'int (*eof)', 'void (*destroy)');
ok $common_order[0] < $common_order[1]
    && $common_order[1] < $common_order[2]
    && $common_order[2] < $common_order[3],
    'native input ABI prefix follows the HTTP1 create/input/eof/destroy order';
ok index($header, 'int (*output)') > $common_order[3],
    'HTTP2 output operations extend the common input ABI prefix';

my (@errors, $request_seen, $response_seen, $complete);
my $server = Unblock::HTTP2::Server->new(
    on_request => sub {
        my ($transaction, $request) = @_;
        $request_seen = $request;
    },
    on_request_end => sub {
        my ($transaction) = @_;
        $transaction->respond(
            Uniform::HTTP::Response->new(
                status => 200,
                body   => 'native-response',
                headers => [
                    [ 'x-native-response', 'yes' ],
                ],
            ),
        );
    },
    on_error => sub {
        my ($transaction, $error) = @_;
        push @errors, "server: $error";
    },
);

my $client = Unblock::HTTP2::Client->new(
    on_ping_ack => sub { },
);
my $client_driver =
    Unblock::HTTP2::_nghttp2::NativeDriver->new($client);
my $server_driver =
    Unblock::HTTP2::_nghttp2::NativeDriver->new($server);

ok $client_driver->want_read, 'native client reports read interest';
ok $server_driver->want_read, 'native server reports read interest';

my $fragment_next_client_write = 1;

sub feed_native {
    my ($driver, $bytes, $fragment) = @_;
    return 0 unless length $bytes;

    if ($fragment && length($bytes) > 1) {
        my $split = int(length($bytes) / 2);
        my @parts = (
            substr($bytes, 0, $split),
            substr($bytes, $split),
        );

        my $total = 0;
        for my $part (@parts) {
            my ($status, $consumed) = $driver->feed($part);
            is $status, Unblock::HTTP2::NativeABI::INPUT_OK(),
                'fragmented native input is accepted';
            is $consumed, length($part),
                'fragmented native input consumes its complete window';
            $total += $consumed;
        }
        return $total;
    }

    my ($status, $consumed) = $driver->feed($bytes);
    is $status, Unblock::HTTP2::NativeABI::INPUT_OK(),
        'native input is accepted';
    is $consumed, length($bytes),
        'native input consumes its complete window';
    return $consumed;
}

sub transfer_native {
    my ($from, $from_driver, $to_driver, $fragment) = @_;
    return 0 unless $from_driver->want_write;

    my ($status, $bytes, $produced) = $from_driver->drain;
    is $status, Unblock::HTTP2::NativeABI::OUTPUT_OK(),
        'native output drain succeeds';
    is $produced, length($bytes),
        'native output reports the bytes accepted by the sink';

    return 0 unless length $bytes;
    return feed_native($to_driver, $bytes, $fragment);
}

sub pump_native {
    my ($until) = @_;
    my $turns = 0;

    for (;;) {
        my $moved = 0;
        $moved += transfer_native(
            $client,
            $client_driver,
            $server_driver,
            $fragment_next_client_write,
        );
        $fragment_next_client_write = 0;
        $moved += transfer_native(
            $server,
            $server_driver,
            $client_driver,
            0,
        );

        last if $until && $until->();
        last unless $moved;
        die 'native transport pump did not settle'
            if ++$turns > 10_000;
    }
}

pump_native();

sub transfer_direct {
    my ($from_driver, $to_driver) = @_;
    return 0 unless $from_driver->want_write;

    my ($output_status, $input_status, $moved) =
        $from_driver->transfer_to($to_driver);

    is $output_status, Unblock::HTTP2::NativeABI::OUTPUT_OK(),
        'direct native bridge drains output';
    is $input_status, Unblock::HTTP2::NativeABI::INPUT_OK(),
        'direct native bridge feeds destination input';
    return $moved;
}

sub pump_direct {
    my ($until) = @_;
    my $turns = 0;

    for (;;) {
        my $moved = 0;
        $moved += transfer_direct($client_driver, $server_driver);
        $moved += transfer_direct($server_driver, $client_driver);

        last if $until && $until->();
        last unless $moved;
        die 'direct native transport pump did not settle'
            if ++$turns > 10_000;
    }
}

my $transaction = $client->request(
    Uniform::HTTP::Request->new(
        method    => 'POST',
        target    => '/native',
        scheme    => 'https',
        authority => 'example.test',
        body      => 'native-request',
        headers   => [
            [ 'x-native-request', 'yes' ],
        ],
    ),
    on_response => sub {
        my ($transaction, $response) = @_;
        $response_seen = $response;
    },
    on_complete => sub {
        $complete = 1;
    },
    on_error => sub {
        my ($transaction, $error) = @_;
        push @errors, "client: $error";
    },
);

pump_direct(sub { $complete });

ok $complete, 'native transport completes an HTTP/2 transaction';
isa_ok $request_seen, 'Uniform::HTTP::Request';
is $request_seen->target, '/native',
    'native server input preserves request target';
is $request_seen->header('x-native-request'), 'yes',
    'native server input preserves request headers';
isa_ok $response_seen, 'Uniform::HTTP::Response';
is $response_seen->status, 200,
    'native client input preserves response status';
is $response_seen->header('x-native-response'), 'yes',
    'native client input preserves response headers';
is_deeply \@errors, [], 'native transport exchange reports no errors';

$client->ping('12345678');
my ($pause_status, $pause_bytes, $pause_produced) =
    $client_driver->drain(1);
is $pause_status, Unblock::HTTP2::NativeABI::OUTPUT_OK(),
    'native output supports transport pause';
is $pause_produced, length($pause_bytes),
    'paused native output reports the accepted chunk';
ok length($pause_bytes), 'paused native output produces a chunk';
feed_native($server_driver, $pause_bytes, 0);
pump_direct();

my $eof_status = $server_driver->eof;
is $eof_status, Unblock::HTTP2::NativeABI::INPUT_CLOSED(),
    'native EOF closes the HTTP/2 connection';
ok $server->is_closed, 'native EOF updates normal engine close state';
like $server->close_reason, qr/transport reached EOF/,
    'native EOF preserves a useful close reason';

done_testing;
