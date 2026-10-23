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
        mask_key => delete($option{mask_key}) || "\x01\x02\x03\x04",
        %option,
    );
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
            on_message => sub {
                my ($ws, $payload, $type) = @_;
                if ($type eq 'text') {
                    $ws->send_text($payload);
                }
                else {
                    $ws->send_binary($payload);
                }
            },
            on_error => sub {
                my ($ws, $error) = @_;
                push @error, $error;
            },
        );

        my $wire =
            client_frame(opcode => 1, payload => 'Hello, world!')
            . client_frame(
                opcode   => 1,
                payload  => 'invalid-rsv',
                rsv2     => 1,
                mask_key => "\x05\x06\x07\x08",
            )
            . client_frame(
                opcode   => 9,
                payload  => 'late-ping',
                mask_key => "\x09\x0a\x0b\x0c",
            );

        $server->input($wire);
        ok(@error, 'later malformed frame reports protocol error');

        my $parser = Unblock::WebSocket::_Frame->new_parser(
            expect_masked  => 0,
            max_frame_size => 1024,
        );
        $parser->input($server->output);

        my @frame;
        while (my $frame = $parser->next_frame) {
            push @frame, $frame;
        }

        is scalar(@frame), 2,
            'only valid-message response and protocol Close are emitted';
        is $frame[0]{opcode}, 1,
            'valid earlier message response is emitted before Close';
        is $frame[0]{payload}, 'Hello, world!',
            'valid earlier message response payload is preserved';
        is $frame[1]{opcode}, 8,
            'protocol Close follows the valid earlier response';
        is unpack('n', substr($frame[1]{payload}, 0, 2)), 1002,
            'reserved-bit failure uses Close 1002';

        ok(
            !grep({ $_->{opcode} == 10 } @frame),
            'Ping after malformed frame does not produce Pong',
        );
    };
}

done_testing;
