use strict;
use warnings;

use Test2::V0;

use Unblock::HTTP3::_Native;
use Unblock::HTTP3::Transaction;
use Uniform::HTTP::Response;
use Unblock::HTTP3::Body::Reader;

{
    package Unblock::HTTP3::TestReceiveConnection;

    sub new {
        return bless {
            consumed    => [],
            completions => 0,
        }, shift;
    }

    sub _consume_received_body {
        my ($self, $transaction, $kind, $amount) = @_;
        push @{ $self->{consumed} }, [ $kind, $amount ];
        return;
    }

    sub _maybe_complete_transaction {
        my ($self, $stream_id) = @_;
        ++$self->{completions};
        return;
    }
}

sub buffered_transaction {
    my ($response) = @_;

    return bless {
        response                 => $response,
        response_receive_mode    => 'buffered',
        response_buffered_body   => '',
        response_buffered_chunks => [],
        response_buffered_bytes  => 0,
        response_buffered_seen   => 0,
    }, 'Unblock::HTTP3::Transaction';
}

sub terminal_transaction {
    return bless {
        connection               => undef,
        request_body             => undef,
        response_body            => undef,
        datagram_queue           => [],
        datagram_callback        => undef,
        state                    => 'active',
        request_buffered_body    => '',
        request_buffered_chunks  => [],
        request_buffered_bytes   => 0,
        request_buffered_seen    => 0,
        response_buffered_body   => '',
        response_buffered_chunks => [],
        response_buffered_bytes  => 0,
        response_buffered_seen   => 0,
    }, 'Unblock::HTTP3::Transaction';
}

my $response = Uniform::HTTP::Response->new(status => 200);
my $buffered = buffered_transaction($response);

my $first = 'first-';
my $second = 'second';
my $third = '-third';

$buffered->_append_buffered_body('response', $first);
$buffered->_append_buffered_body('response', $second);
$buffered->_append_buffered_body('response', $third);

is(
    $buffered->_buffered_body_bytes('response'),
    length('first-second-third'),
    'buffered receive accounts for all retained DATA bytes',
);

$first = 'mutated-first';
$second = 'mutated-second';
$third = 'mutated-third';

$buffered->_finish_received_message('response');

is(
    $response->body,
    'first-second-third',
    'buffered receive retains chunk data independently of caller mutation',
);
ok($response->is_complete, 'buffered response completes normally');
is(
    $buffered->_buffered_body_bytes('response'),
    0,
    'buffered receive byte accounting returns to zero after finalization',
);
is(
    $buffered->{response_buffered_body},
    '',
    'buffered receive releases buffered storage after finalization',
);
is(
    scalar @{ $buffered->{response_buffered_chunks} },
    0,
    'buffered receive releases retained chunk storage after finalization',
);

my $large_response = Uniform::HTTP::Response->new(status => 200);
my $large = buffered_transaction($large_response);
my $large_first = 'A' x 16_384;
my $large_second = 'B' x 65_536;
my $large_expected = $large_first . $large_second;

$large->_append_buffered_body('response', $large_first);
$large->_append_buffered_body('response', $large_second);

is(
    $large->_buffered_body_bytes('response'),
    length($large_expected),
    'large buffered chunks use accurate retained-byte accounting',
);

$large_first = 'changed-large-first';
$large_second = 'changed-large-second';

$large->_finish_received_message('response');

is(
    $large_response->body,
    $large_expected,
    'large retained buffered chunks survive caller mutation and coalesce correctly',
);
is(
    $large->_buffered_body_bytes('response'),
    0,
    'large buffered receive accounting returns to zero after finalization',
);
is(
    $large->{response_buffered_body},
    '',
    'large retained chunk storage is released after finalization',
);

my $single_response = Uniform::HTTP::Response->new(status => 200);
my $single = buffered_transaction($single_response);
my $single_chunk = 'single-owned-chunk';

$single->_append_buffered_body('response', $single_chunk);
$single_chunk = 'changed-after-append';
$single->_finish_received_message('response');

is(
    $single_response->body,
    'single-owned-chunk',
    'single buffered chunk keeps stable lifetime through finalization',
);

my $empty_response = Uniform::HTTP::Response->new(status => 200);
my $empty = buffered_transaction($empty_response);

$empty->_append_buffered_body('response', '');
$empty->_finish_received_message('response');

ok(
    $empty_response->has_buffered_body,
    'received empty DATA still produces an explicit buffered body',
);
is($empty_response->body, '', 'explicit empty buffered body is preserved');

my $connection = Unblock::HTTP3::TestReceiveConnection->new;
my $reader_tx = bless {
    connection => $connection,
    stream_id  => 17,
}, 'Unblock::HTTP3::Transaction';

my $reader = Unblock::HTTP3::Body::Reader->_new(
    $reader_tx,
    'response',
);

my $reader_first = 'reader-one';
my $reader_second = 'reader-two';

$reader->_push_owned($reader_first);
$reader->_push_owned($reader_second);
$reader->_mark_end;

$reader_first = 'changed-one';
$reader_second = 'changed-two';

is(
    $reader->pending_bytes,
    length('reader-one') + length('reader-two'),
    'streaming reader accounts for queued owned chunks',
);
ok(
    !$reader->is_complete,
    'streaming reader waits for queued chunks after peer end',
);

is(
    $reader->next_chunk,
    'reader-one',
    'first owned streaming chunk survives caller mutation',
);
is(
    $connection->{consumed},
    [ [ response => length('reader-one') ] ],
    'receive credit is returned only for the first consumed chunk',
);
is(
    $reader->pending_bytes,
    length('reader-two'),
    'partial streaming consumption leaves later bytes pending',
);
ok(
    !$reader->is_complete,
    'reader remains incomplete while one chunk is still pending',
);

is(
    $reader->next_chunk,
    'reader-two',
    'second owned streaming chunk survives caller mutation',
);
is(
    $connection->{consumed},
    [
        [ response => length('reader-one') ],
        [ response => length('reader-two') ],
    ],
    'receive credit follows application consumption for every chunk',
);
is($reader->pending_bytes, 0, 'streaming reader releases all queued bytes');
ok($reader->is_complete, 'streaming reader completes after final chunk');
is(
    $connection->{completions},
    1,
    'reader completion notifies the Transaction once',
);

my $cancel_calls = 0;
my $cancel_reader = Unblock::HTTP3::Body::Reader->_new(
    $reader_tx,
    'response',
    on_cancel => sub { ++$cancel_calls },
);

$cancel_reader->_push_owned('cancel-one');
$cancel_reader->_push_owned('cancel-two');

ok($cancel_reader->pending_bytes > 0, 'cancellation test has retained chunks');
$cancel_reader->_cancel;

ok($cancel_reader->is_cancelled, 'streaming reader reports cancellation');
is($cancel_reader->pending_bytes, 0, 'cancellation releases pending byte count');
is(
    scalar @{ $cancel_reader->{queue} },
    0,
    'cancellation releases all queued streaming chunks',
);
is($cancel_calls, 1, 'streaming cancellation callback runs once');

my $error_tx = terminal_transaction();
$error_tx->_append_buffered_body('response', 'E' x 16_384);
ok(
    $error_tx->_buffered_body_bytes('response') > 0,
    'error cleanup test starts with retained buffered data',
);

$error_tx->_mark_error('test receive failure');

is($error_tx->state, 'error', 'transaction enters error state');
is(
    $error_tx->_buffered_body_bytes('response'),
    0,
    'transaction error releases buffered receive accounting',
);
is(
    $error_tx->{response_buffered_body},
    '',
    'transaction error releases buffered receive storage',
);
is(
    scalar @{ $error_tx->{response_buffered_chunks} },
    0,
    'transaction error releases retained buffered chunks',
);

my $cancel_tx = terminal_transaction();
$cancel_tx->_append_buffered_body('request', 'C' x 65_536);
ok(
    $cancel_tx->_buffered_body_bytes('request') > 0,
    'cancel cleanup test starts with retained buffered data',
);

$cancel_tx->_mark_cancelled;

is($cancel_tx->state, 'cancelled', 'transaction enters cancelled state');
is(
    $cancel_tx->_buffered_body_bytes('request'),
    0,
    'transaction cancellation releases buffered receive accounting',
);
is(
    $cancel_tx->{request_buffered_body},
    '',
    'transaction cancellation releases buffered receive storage',
);
is(
    scalar @{ $cancel_tx->{request_buffered_chunks} },
    0,
    'transaction cancellation releases retained buffered chunks',
);

my $native_sender = Unblock::HTTP3::_Native->client(
    65_536, 0, 0, 0, 0,
);
my $native_receiver = Unblock::HTTP3::_Native->server(
    65_536, 0, 0, 0, 0,
);

$native_sender->bind_streams(2, 6, 10);
$native_receiver->bind_streams(3, 7, 11);
$native_receiver->set_max_client_streams_bidi(100);

$native_sender->submit_request(
    0,
    [
        [ ':method',    'POST' ],
        [ ':scheme',    'https' ],
        [ ':authority', 'example.test' ],
        [ ':path',      '/incoming-ownership' ],
    ],
    undef,
    1,
);

my $timestamp = 1;

while (my $out = $native_sender->next_write) {
    my ($stream_id, $bytes, $fin) = @$out;

    my $read = $native_receiver->read_stream(
        $stream_id,
        $bytes,
        $fin ? 1 : 0,
        $timestamp++,
    );

    is(scalar(@$read), 1, 'native receiver accepts setup stream bytes');

    $native_sender->add_write_offset(
        $stream_id,
        length($bytes),
    );
}

while ($native_receiver->next_event) {
    # Discard request-header setup events.
}

my $native_source = 'native-owned-data';
$native_sender->append_body(0, $native_source, 0);
$native_source = 'mutated-before-send-does-not-matter';

my $native_data_seen = 0;

while (my $out = $native_sender->next_write) {
    my ($stream_id, $bytes, $fin) = @$out;
    my $wire_length = length($bytes);

    my $read = $native_receiver->read_stream(
        $stream_id,
        $bytes,
        $fin ? 1 : 0,
        $timestamp++,
    );

    is(scalar(@$read), 1, 'native receiver accepts DATA stream bytes');

    $bytes = 'mutated-after-read';

    $native_sender->add_write_offset(
        $stream_id,
        $wire_length,
    );
}

while (my $event = $native_receiver->next_event) {
    next unless $event->[0] eq 'data';

    is(
        $event->[2],
        'native-owned-data',
        'native DATA event owns bytes beyond libnghttp3 read callback input',
    );
    ++$native_data_seen;
}

is($native_data_seen, 1, 'native ownership test receives one DATA event');

done_testing;
