use strict;
use warnings;
use Test::More;

use Unblock::WebSocket;
use Unblock::WebSocket::Server;
use Unblock::WebSocket::_Deflate;
use Unblock::WebSocket::_Frame;

plan skip_all => 'native engine is not available'
    unless Unblock::WebSocket->native_available;

require Unblock::WebSocket::_Native;

sub masked_frame {
    my (%option) = @_;
    return Unblock::WebSocket::_Frame->encode(
        masked   => 1,
        mask_key => delete($option{mask_key}) || "\x01\x02\x03\x04",
        %option,
    );
}

{
    my $native = Unblock::WebSocket::_Native->new('server', 4096, 1);
    my $ping = masked_frame(
        opcode  => 9,
        payload => 'bad-rsv1',
        rsv1    => 1,
    );

    is_deeply($native->feed($ping), [],
        'compressed flag on control frame produces no event');
    is($native->_error_string, 'RESERVED_BIT',
        'native bridge rejects RSV1 on control frame');
}

{
    my $native = Unblock::WebSocket::_Native->new('server', 4096, 1);
    my $first = masked_frame(
        opcode  => 1,
        payload => 'part-one',
        fin     => 0,
        rsv1    => 1,
    );
    my $continuation = masked_frame(
        opcode   => 0,
        payload  => 'part-two',
        fin      => 1,
        rsv1     => 1,
        mask_key => "\x05\x06\x07\x08",
    );

    is_deeply($native->feed($first . $continuation), [],
        'RSV1 continuation produces no completed event');
    is($native->_error_string, 'RESERVED_BIT',
        'native bridge rejects RSV1 on continuation frame');
}

{
    my @error;
    my $server = Unblock::WebSocket::Server->new(
        backend            => 'native',
        permessage_deflate => {},
        on_error => sub {
            my ($ws, $message) = @_;
            push @error, $message;
        },
    );

    my $wire = masked_frame(
        opcode  => 2,
        payload => "\xff\xff\xff",
        rsv1    => 1,
    );

    $server->input($wire);
    like($error[0] || '', qr/deflate|decompress/i,
        'malformed compressed payload reports decompression failure');

    my $parser = Unblock::WebSocket::_Frame->new_parser(
        expect_masked  => 0,
        max_frame_size => 125,
        allow_rsv1     => 1,
    );
    $parser->input($server->output);
    my $close = $parser->next_frame;
    is($close->{opcode}, 8,
        'malformed compressed payload emits Close');
    is(unpack('n', substr($close->{payload}, 0, 2)), 1002,
        'malformed compressed payload uses Close 1002');
}

{
    my @message;
    my @error;
    my $server = Unblock::WebSocket::Server->new(
        backend            => 'native',
        permessage_deflate => {},
        on_message => sub {
            my ($ws, $payload, $type) = @_;
            push @message, [ $payload, $type ];
            $ws->send_text($payload);
        },
        on_error => sub {
            my ($ws, $message) = @_;
            push @error, $message;
        },
    );

    my $codec = Unblock::WebSocket::_Deflate->new(
        role             => 'client',
        config           => {},
        max_message_size => 4096,
    );
    my $compressed = $codec->compress('before compressed error');

    my $valid = masked_frame(
        opcode  => 1,
        payload => $compressed,
        rsv1    => 1,
    );
    my $bad = masked_frame(
        opcode   => 2,
        payload  => 'bad-rsv2',
        rsv2     => 1,
        mask_key => "\x05\x06\x07\x08",
    );

    $server->input($valid . $bad);

    is_deeply(
        \@message,
        [ [ 'before compressed error', 'text' ] ],
        'valid compressed message preceding malformed frame is delivered',
    );
    ok(@error, 'later malformed frame reports error');

    my $parser = Unblock::WebSocket::_Frame->new_parser(
        expect_masked  => 0,
        max_frame_size => 4096,
        allow_rsv1     => 1,
    );
    $parser->input($server->output);

    my @frame;
    while (my $frame = $parser->next_frame) {
        push @frame, $frame;
    }

    is(scalar(@frame), 2,
        'compressed pre-error response is followed by protocol Close');
    is($frame[0]{opcode}, 1,
        'compressed application response retains text opcode');
    ok($frame[0]{rsv1},
        'compressed application response retains RSV1');
    is($frame[1]{opcode}, 8,
        'protocol Close follows compressed application response');
    is(unpack('n', substr($frame[1]{payload}, 0, 2)), 1002,
        'later reserved-bit failure uses Close 1002');
}


{
    my @error;
    my $server = Unblock::WebSocket::Server->new(
        backend            => 'native',
        permessage_deflate => {},
        on_error => sub {
            my ($ws, $message) = @_;
            push @error, $message;
        },
    );

    my $codec = Unblock::WebSocket::_Deflate->new(
        role             => 'client',
        config           => {},
        max_message_size => 4096,
    );
    my $compressed = $codec->compress("\xff");

    my $wire = masked_frame(
        opcode  => 1,
        payload => $compressed,
        rsv1    => 1,
    );

    $server->input($wire);
    like($error[0] || '', qr/UTF-8/i,
        'invalid decompressed UTF-8 reports text error');

    my $parser = Unblock::WebSocket::_Frame->new_parser(
        expect_masked  => 0,
        max_frame_size => 125,
        allow_rsv1     => 1,
    );
    $parser->input($server->output);
    my $close = $parser->next_frame;
    is($close->{opcode}, 8,
        'invalid decompressed UTF-8 emits Close');
    is(unpack('n', substr($close->{payload}, 0, 2)), 1007,
        'invalid decompressed UTF-8 uses Close 1007');
}

{
    my @message;
    my @ping;
    my $server = Unblock::WebSocket::Server->new(
        backend            => 'native',
        permessage_deflate => {},
        on_message => sub {
            my ($ws, $payload, $type) = @_;
            push @message, [ $payload, $type ];
        },
        on_ping => sub {
            my ($ws, $payload) = @_;
            push @ping, $payload;
        },
    );

    my $codec = Unblock::WebSocket::_Deflate->new(
        role             => 'client',
        config           => {},
        max_message_size => 4096,
    );
    my $compressed = $codec->compress('compressed fragmented ping ' x 20);
    my $cut = int(length($compressed) / 2);

    my $first = masked_frame(
        opcode  => 1,
        payload => substr($compressed, 0, $cut),
        fin     => 0,
        rsv1    => 1,
    );
    my $ping = masked_frame(
        opcode   => 9,
        payload  => 'between',
        mask_key => "\x05\x06\x07\x08",
    );
    my $last = masked_frame(
        opcode   => 0,
        payload  => substr($compressed, $cut),
        fin      => 1,
        mask_key => "\x09\x0a\x0b\x0c",
    );

    $server->input($first . $ping . $last);

    is_deeply(\@ping, [ 'between' ],
        'Ping interleaved with compressed fragments is delivered');
    is_deeply(
        \@message,
        [ [ 'compressed fragmented ping ' x 20, 'text' ] ],
        'control interleaving preserves compressed fragment state',
    );
}


{
    my @message;
    my $server = Unblock::WebSocket::Server->new(
        backend            => 'native',
        permessage_deflate => {},
        on_message => sub {
            my ($ws, $payload, $type) = @_;
            push @message, [ $payload, $type ];
        },
    );

    my $codec = Unblock::WebSocket::_Deflate->new(
        role             => 'client',
        config           => {},
        max_message_size => 4096,
    );

    my $first_payload = 'history-message-' x 20;
    my $second_payload = 'history-message-' x 20;
    my $first_compressed = $codec->compress($first_payload);
    my $second_compressed = $codec->compress($second_payload);

    my $first = masked_frame(
        opcode  => 2,
        payload => $first_compressed,
        rsv1    => 1,
    );
    my $plain = masked_frame(
        opcode   => 2,
        payload  => 'plain-between',
        mask_key => "\x05\x06\x07\x08",
    );
    my $second = masked_frame(
        opcode   => 2,
        payload  => $second_compressed,
        rsv1     => 1,
        mask_key => "\x09\x0a\x0b\x0c",
    );

    $server->input($first . $plain . $second);

    is_deeply(
        \@message,
        [
            [ $first_payload, 'binary' ],
            [ 'plain-between', 'binary' ],
            [ $second_payload, 'binary' ],
        ],
        'uncompressed interleaving does not disturb compression history',
    );
}

done_testing;
