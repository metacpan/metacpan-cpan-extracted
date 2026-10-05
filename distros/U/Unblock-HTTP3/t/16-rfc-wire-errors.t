use strict;
use warnings;

use Test2::V0;

use Unblock::HTTP3::_Native;

sub h3_varint {
    my ($value) = @_;

    die "test varint must be a non-negative integer"
        if !defined($value) || $value < 0 || int($value) != $value;

    return pack('C', $value)
        if $value <= 63;
    return pack('n', $value | 0x4000)
        if $value <= 16_383;
    return pack('N', $value | 0x8000_0000)
        if $value <= 1_073_741_823;

    die "test varint is larger than this test needs";
}

sub h3_frame {
    my ($type, $payload) = @_;
    $payload = '' unless defined $payload;

    return h3_varint($type)
        . h3_varint(length($payload))
        . $payload;
}

sub control_stream {
    my (@frames) = @_;

    return h3_varint(0)
        . h3_frame(0x04, '')
        . join('', @frames);
}

sub read_error {
    my (%args) = @_;

    my $result = $args{native}->read_stream(
        $args{stream_id},
        $args{bytes},
        $args{fin} ? 1 : 0,
        $args{timestamp} // 1,
    );

    is(
        scalar(@$result),
        4,
        "$args{label}: native parser reports a fatal HTTP/3 error",
    );
    ok(
        !defined($result->[0]),
        "$args{label}: fatal parser result has no consumed byte count",
    );
    is(
        $result->[2],
        $args{code},
        "$args{label}: maps to the required HTTP/3 application error",
    );

    return $result;
}

{
    my $native = Unblock::HTTP3::_Native->server;

    read_error(
        native    => $native,
        stream_id => 2,
        bytes     => h3_varint(0) . h3_frame(0x21, ''),
        code      => 0x010a,
        label     => 'control stream frame before SETTINGS',
    );
}

{
    my $native = Unblock::HTTP3::_Native->server;

    read_error(
        native    => $native,
        stream_id => 2,
        bytes     => control_stream(h3_frame(0x04, '')),
        code      => 0x0105,
        label     => 'second SETTINGS frame',
    );
}

{
    my $native = Unblock::HTTP3::_Native->server;
    my $payload = h3_varint(0x02) . h3_varint(0);

    read_error(
        native    => $native,
        stream_id => 2,
        bytes     => h3_varint(0) . h3_frame(0x04, $payload),
        code      => 0x0109,
        label     => 'reserved HTTP/2 SETTINGS identifier',
    );
}

{
    my $native = Unblock::HTTP3::_Native->server;
    my $payload =
        h3_varint(0x06) . h3_varint(1024)
        . h3_varint(0x06) . h3_varint(2048);

    my $result = $native->read_stream(
        2,
        h3_varint(0) . h3_frame(0x04, $payload),
        0,
        1,
    );

    is(
        scalar(@$result),
        1,
        'duplicate SETTINGS identifiers may be tolerated by the receiver',
    );
}

{
    my $native = Unblock::HTTP3::_Native->server;

    read_error(
        native    => $native,
        stream_id => 2,
        bytes     => control_stream(h3_frame(0x02, '')),
        code      => 0x0105,
        label     => 'reserved HTTP/2 frame type',
    );
}

{
    my $native = Unblock::HTTP3::_Native->server;

    read_error(
        native    => $native,
        stream_id => 2,
        bytes     => control_stream(h3_frame(0x00, '')),
        code      => 0x0105,
        label     => 'DATA frame on control stream',
    );
}

{
    my $native = Unblock::HTTP3::_Native->server;
    my $payload = h3_varint(0x21) . h3_varint(7);
    my $result = $native->read_stream(
        2,
        h3_varint(0) . h3_frame(0x04, $payload) . h3_frame(0x21, ''),
        0,
        1,
    );

    is(
        scalar(@$result),
        1,
        'GREASE setting and frame type are accepted',
    );
    ok(
        $result->[0] >= 0,
        'GREASE input reports normal byte consumption',
    );
}

{
    my $native = Unblock::HTTP3::_Native->server;

    my $first = $native->read_stream(
        2,
        control_stream(),
        0,
        1,
    );

    is(scalar(@$first), 1, 'first control stream is accepted');

    read_error(
        native    => $native,
        stream_id => 6,
        bytes     => h3_varint(0),
        code      => 0x0103,
        label     => 'second control stream',
        timestamp => 2,
    );
}

{
    my $native = Unblock::HTTP3::_Native->server;

    read_error(
        native    => $native,
        stream_id => 2,
        bytes     => control_stream(),
        fin       => 1,
        code      => 0x0104,
        label     => 'closed control stream',
    );
}

for my $case (
    [ 0x02, 'QPACK encoder' ],
    [ 0x03, 'QPACK decoder' ],
) {
    my ($stream_type, $name) = @$case;
    my $native = Unblock::HTTP3::_Native->server;

    my $first = $native->read_stream(
        2,
        h3_varint($stream_type),
        0,
        1,
    );

    is(scalar(@$first), 1, "first $name stream is accepted");

    read_error(
        native    => $native,
        stream_id => 6,
        bytes     => h3_varint($stream_type),
        code      => 0x0103,
        label     => "second $name stream",
        timestamp => 2,
    );
}


{
    my $native = Unblock::HTTP3::_Native->server(
        65_536,
        0,
        100,
    );

    read_error(
        native    => $native,
        stream_id => 2,
        bytes     => h3_varint(0x02) . "\x21",
        code      => 0x0201,
        label     => 'QPACK encoder exceeds dynamic table capacity',
    );
}

{
    my $native = Unblock::HTTP3::_Native->server;

    read_error(
        native    => $native,
        stream_id => 2,
        bytes     => h3_varint(0x03) . "\x00",
        code      => 0x0202,
        label     => 'QPACK decoder sends zero Insert Count Increment',
    );
}

{
    my $native = Unblock::HTTP3::_Native->server;

    read_error(
        native    => $native,
        stream_id => 2,
        bytes     => h3_varint(0x01) . h3_varint(0),
        code      => 0x0103,
        label     => 'client-initiated push stream',
    );
}

{
    my $native = Unblock::HTTP3::_Native->client;

    read_error(
        native    => $native,
        stream_id => 3,
        bytes     => control_stream(
            h3_frame(0x0d, h3_varint(0)),
        ),
        code      => 0x0105,
        label     => 'server-sent MAX_PUSH_ID',
    );
}


{
    my $native = Unblock::HTTP3::_Native->server;
    my $result = $native->read_stream(
        2,
        h3_varint(0x21),
        1,
        1,
    );

    is(
        scalar(@$result),
        1,
        'unknown unidirectional stream type can close without failing connection',
    );
}

{
    my $native = Unblock::HTTP3::_Native->server;

    read_error(
        native    => $native,
        stream_id => 0,
        bytes     => h3_frame(0x00, ''),
        code      => 0x0105,
        label     => 'DATA before initial request HEADERS',
    );
}

{
    my $native = Unblock::HTTP3::_Native->server;
    my $priority = h3_frame(
        0x0f0700,
        h3_varint(0) . 'u=1',
    );

    read_error(
        native    => $native,
        stream_id => 0,
        bytes     => $priority,
        code      => 0x0105,
        label     => 'PRIORITY_UPDATE on request stream',
    );
}

{
    my $native = Unblock::HTTP3::_Native->client;
    my $priority = h3_frame(
        0x0f0700,
        h3_varint(0) . 'u=1',
    );

    read_error(
        native    => $native,
        stream_id => 3,
        bytes     => control_stream($priority),
        code      => 0x0105,
        label     => 'server-sent PRIORITY_UPDATE',
    );
}

{
    my $native = Unblock::HTTP3::_Native->server;
    my $priority = h3_frame(
        0x0f0700,
        h3_varint(2) . 'u=1',
    );

    read_error(
        native    => $native,
        stream_id => 2,
        bytes     => control_stream($priority),
        code      => 0x0108,
        label     => 'request PRIORITY_UPDATE targeting non-request stream',
    );
}

{
    my $native = Unblock::HTTP3::_Native->client;

    read_error(
        native    => $native,
        stream_id => 3,
        bytes     => control_stream(
            h3_frame(0x07, h3_varint(2)),
        ),
        code      => 0x0108,
        label     => 'server GOAWAY with non-request stream ID',
    );
}

{
    my $native = Unblock::HTTP3::_Native->client;

    read_error(
        native    => $native,
        stream_id => 3,
        bytes     => control_stream(
            h3_frame(0x07, h3_varint(4)),
            h3_frame(0x07, h3_varint(8)),
        ),
        code      => 0x0108,
        label     => 'increasing GOAWAY identifier',
    );
}


done_testing;
