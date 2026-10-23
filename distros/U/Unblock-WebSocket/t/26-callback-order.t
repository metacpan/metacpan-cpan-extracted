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

sub backends {
    my @backend = ('perl');
    push @backend, 'native' if Unblock::WebSocket->native_available;
    return @backend;
}

for my $backend (backends()) {
    subtest "$backend callback stop" => sub {
        my @message;
        my $server = Unblock::WebSocket::Server->new(
            backend => $backend,
            on_message => sub {
                my ($ws, $payload, $type) = @_;
                push @message, [ $payload, $type ];
                $ws->abort;
            },
        );

        $server->input(
            client_frame(opcode => 1, payload => 'first')
            . client_frame(opcode => 1, payload => 'second')
        );

        is_deeply(
            \@message,
            [ [ 'first', 'text' ] ],
            'aborting from callback stops coalesced batch immediately',
        );
        ok($server->is_closed, 'callback abort closes protocol object');
    };

    subtest "$backend ping ordering" => sub {
        my @ping;
        my $server = Unblock::WebSocket::Server->new(
            backend => $backend,
            on_ping => sub {
                my ($ws, $payload) = @_;
                push @ping, $payload;
            },
        );

        $server->input(
            client_frame(opcode => 9, payload => 'one')
            . client_frame(
                opcode => 9,
                payload => 'two',
                mask_key => "\x05\x06\x07\x08",
            )
        );

        is_deeply(\@ping, [ 'one', 'two' ],
            'both coalesced Ping callbacks are delivered in wire order');

        my $parser = Unblock::WebSocket::_Frame->new_parser(
            expect_masked  => 0,
            max_frame_size => 125,
        );
        $parser->input($server->output);

        my @pong;
        while (my $frame = $parser->next_frame) {
            push @pong, $frame->{payload} if $frame->{opcode} == 10;
        }

        is_deeply(\@pong, [ 'one', 'two' ],
            'one Pong is emitted for each Ping in wire order');
    };
}

done_testing;
