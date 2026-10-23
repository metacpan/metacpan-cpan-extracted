use strict;
use warnings;
use Test::More;

use Unblock::WebSocket::_Frame;

my $wire = Unblock::WebSocket::_Frame->encode(
    opcode   => 1,
    payload  => 'hello',
    masked   => 1,
    mask_key => "\x01\x02\x03\x04",
);

my $parser = Unblock::WebSocket::_Frame->new_parser(
    expect_masked  => 1,
    max_frame_size => 1024,
);

$parser->input(substr($wire, 0, 3));
ok !defined($parser->next_frame), 'partial frame waits for more bytes';
$parser->input(substr($wire, 3));
my $frame = $parser->next_frame;
is $frame->{type}, 'text', 'text opcode decoded';
is $frame->{payload}, 'hello', 'masked payload decoded';
ok $frame->{fin}, 'frame is final';

my $large = 'x' x 126;
my $large_wire = Unblock::WebSocket::_Frame->encode(
    opcode  => 2,
    payload => $large,
    masked  => 0,
);
my $server_parser = Unblock::WebSocket::_Frame->new_parser(
    expect_masked => 0,
    max_frame_size => 1024,
);
$server_parser->input($large_wire);
my $large_frame = $server_parser->next_frame;
is length($large_frame->{payload}), 126, '16-bit payload length works';

my $bad_control = eval {
    Unblock::WebSocket::_Frame->encode(
        opcode => 9,
        payload => 'x' x 126,
        masked => 0,
    );
    1;
};
ok !$bad_control, 'oversized control frame is rejected';
like $@, qr/125 bytes/, 'control-frame error is clear';

done_testing;
