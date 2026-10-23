use strict;
use warnings;
use Test::More;

use Unblock::WebSocket::Server;
use Unblock::WebSocket::_Frame;

my @error;
my $server = Unblock::WebSocket::Server->new(
    max_message_size => 4,
    on_error => sub {
        my ($ws, $message) = @_;
        push @error, $message;
    },
);

my $ping = Unblock::WebSocket::_Frame->encode(
    opcode => 9,
    payload => '12345',
    masked => 1,
    mask_key => "\x01\x02\x03\x04",
);
$server->input($ping);
ok !$error[0], 'control payload may exceed max_message_size up to RFC control limit';

my $too_large = Unblock::WebSocket::_Frame->encode(
    opcode => 2,
    payload => '12345',
    masked => 1,
    mask_key => "\x05\x06\x07\x08",
);
$server->input($too_large);
like $error[0], qr/exceeds configured limit/, 'oversized data frame is reported';
ok $server->is_closing, 'size violation begins close handshake';

my $close_parser = Unblock::WebSocket::_Frame->new_parser(
    expect_masked => 0,
    max_frame_size => 125,
);
$close_parser->input($server->output);
my @frames;
while (my $f = $close_parser->next_frame) { push @frames, $f }
my ($close) = grep { $_->{type} eq 'close' } @frames;
ok $close, 'size failure queues Close';
is unpack('n', substr($close->{payload}, 0, 2)), 1009,
    'size failure uses close code 1009';

done_testing;
