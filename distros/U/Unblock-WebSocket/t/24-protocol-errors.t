use strict;
use warnings;
use Test::More;

use Unblock::WebSocket;
use Unblock::WebSocket::Server;
use Unblock::WebSocket::_Frame;

sub client_frame {
    my (%option) = @_;
    return Unblock::WebSocket::_Frame->encode(
        masked   => 1,
        mask_key => "\x01\x02\x03\x04",
        %option,
    );
}

sub close_code_from_wire {
    my ($wire) = @_;
    my $parser = Unblock::WebSocket::_Frame->new_parser(
        expect_masked  => 0,
        max_frame_size => 1024,
    );
    $parser->input($wire);
    while (my $frame = $parser->next_frame) {
        next unless $frame->{opcode} == 8;
        return length($frame->{payload}) >= 2
            ? unpack('n', substr($frame->{payload}, 0, 2))
            : undef;
    }
    return;
}

sub backends {
    my @backend = ('perl');
    push @backend, 'native' if Unblock::WebSocket->native_available;
    return @backend;
}

for my $backend (backends()) {
    subtest $backend => sub {
        my @error;
        my $server = Unblock::WebSocket::Server->new(
            backend => $backend,
            on_error => sub { push @error, $_[1] },
        );

        $server->input(client_frame(
            opcode  => 0,
            payload => 'orphan',
        ));
        like($error[0] || '', qr/continuation/i,
            'orphan continuation reports protocol error');
        is(close_code_from_wire($server->output), 1002,
            'orphan continuation sends close 1002');

        @error = ();
        $server = Unblock::WebSocket::Server->new(
            backend => $backend,
            on_error => sub { push @error, $_[1] },
        );
        $server->input(
            client_frame(opcode => 1, payload => 'unfinished', fin => 0)
            . client_frame(opcode => 2, payload => 'new message')
        );
        like($error[0] || '', qr/unfinished|partial|continuation/i,
            'overlapping fragmented message reports protocol error');
        is(close_code_from_wire($server->output), 1002,
            'overlapping fragmented message sends close 1002');

        @error = ();
        $server = Unblock::WebSocket::Server->new(
            backend => $backend,
            max_message_size => 5,
            on_error => sub { push @error, $_[1] },
        );
        $server->input(
            client_frame(opcode => 2, payload => 'abc', fin => 0)
            . client_frame(opcode => 0, payload => 'def')
        );
        like($error[0] || '', qr/exceeds configured limit|MAX_RECV_MSG_SIZE/i,
            'fragmented message limit reports error');
        is(close_code_from_wire($server->output), 1009,
            'fragmented message-size failure sends close 1009');

        @error = ();
        $server = Unblock::WebSocket::Server->new(
            backend => $backend,
            on_error => sub { push @error, $_[1] },
        );
        $server->input(client_frame(opcode => 1, payload => "\xff"));
        like($error[0] || '', qr/UTF-8/i,
            'invalid text reports UTF-8 error');
        is(close_code_from_wire($server->output), 1007,
            'invalid UTF-8 sends close 1007');

        for my $case (
            [ "\x03", 1002, qr/Close|close/i, 'one-byte close' ],
            [ pack('n', 1005), 1002, qr/Close|close|BAD_CLOSE/i, 'reserved close code' ],
            [ pack('n', 1000) . "\xff", 1007, qr/UTF-8/i, 'invalid close reason' ],
        ) {
            my ($payload, $expected_code, $pattern, $name) = @$case;
            @error = ();
            $server = Unblock::WebSocket::Server->new(
                backend => $backend,
                on_error => sub { push @error, $_[1] },
            );
            $server->input(client_frame(opcode => 8, payload => $payload));
            like($error[0] || '', $pattern, "$name reports expected error");
            is(close_code_from_wire($server->output), $expected_code,
                "$name sends expected close code");
        }

        my $ok = eval {
            $server = Unblock::WebSocket::Server->new(backend => $backend);
            $server->ping('x' x 126);
            1;
        };
        ok(!$ok, 'outgoing Ping above 125 bytes is rejected');
        like($@, qr/125 bytes/i, 'oversized Ping reports control-frame limit');
    };
}

done_testing;
