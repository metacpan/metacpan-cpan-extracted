use strict;
use warnings;
use Test::More;

use Unblock::WebSocket;
use Unblock::WebSocket::_Frame;

plan skip_all => 'native engine is not available'
    unless Unblock::WebSocket->native_available;

require Unblock::WebSocket::_Native;

my $server = Unblock::WebSocket::_Native->new('server', 1024);

my $valid = Unblock::WebSocket::_Frame->encode(
    opcode   => 1,
    payload  => 'before-error',
    masked   => 1,
    mask_key => "\x01\x02\x03\x04",
);
my $invalid = Unblock::WebSocket::_Frame->encode(
    opcode   => 2,
    payload  => 'bad-rsv',
    masked   => 1,
    mask_key => "\x05\x06\x07\x08",
);
substr($invalid, 0, 1) = chr(ord(substr($invalid, 0, 1)) | 0x40);

my $events = $server->feed($valid . $invalid);
is scalar(@$events), 1,
    'valid event before malformed frame is retained';
is $events->[0][0], 1, 'retained event is text';
is $events->[0][1], 'before-error',
    'retained event payload is intact';
ok $server->_error_code, 'malformed frame records native protocol error';

my $wire = $server->flush;
ok length($wire), 'protocol error generates Close output';
my $parser = Unblock::WebSocket::_Frame->new_parser(
    expect_masked  => 0,
    max_frame_size => 125,
);
$parser->input($wire);
my $close = $parser->next_frame;
is $close->{type}, 'close', 'error output is Close frame';
is unpack('n', substr($close->{payload}, 0, 2)), 1002,
    'reserved-bit protocol error uses Close 1002';

done_testing;
