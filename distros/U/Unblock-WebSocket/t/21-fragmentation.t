use strict;
use warnings;
use Test::More;

use Unblock::WebSocket::Server;
use Unblock::WebSocket::_Frame;

my @message;
my @pong_wire;
my $server = Unblock::WebSocket::Server->new(
    on_message => sub {
        my ($ws, $payload, $type) = @_;
        push @message, [ $payload, $type ];
    },
);

my $first = Unblock::WebSocket::_Frame->encode(
    opcode => 1, payload => 'hel', fin => 0, masked => 1,
    mask_key => "\x01\x02\x03\x04",
);
my $ping = Unblock::WebSocket::_Frame->encode(
    opcode => 9, payload => 'x', masked => 1,
    mask_key => "\x05\x06\x07\x08",
);
my $last = Unblock::WebSocket::_Frame->encode(
    opcode => 0, payload => 'lo', fin => 1, masked => 1,
    mask_key => "\x09\x0a\x0b\x0c",
);

$server->input($first . $ping . $last);
is_deeply $message[0], [ 'hello', 'text' ],
    'fragmented text message is reassembled across control frame';
ok $server->want_write, 'ping generated output while fragmented message was active';

my $client_parser = Unblock::WebSocket::_Frame->new_parser(
    expect_masked => 0,
    max_frame_size => 1024,
);
$client_parser->input($server->output);
my $pong = $client_parser->next_frame;
is $pong->{type}, 'pong', 'interleaved ping produced pong';
is $pong->{payload}, 'x', 'pong payload matches ping';

done_testing;
