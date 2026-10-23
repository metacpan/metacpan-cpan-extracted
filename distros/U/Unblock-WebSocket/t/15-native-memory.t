use strict;
use warnings;
use Test::More;

use Unblock::WebSocket;
use Unblock::WebSocket::_Frame;

plan skip_all => 'native engine is not available'
    unless Unblock::WebSocket->native_available;

require Unblock::WebSocket::_Native;

sub masked_close {
    my ($payload) = @_;
    return Unblock::WebSocket::_Frame->encode(
        opcode   => 8,
        payload  => $payload,
        masked   => 1,
        mask_key => "\x01\x02\x03\x04",
    );
}

for my $case (
    [ "\x03", 'one-byte Close' ],
    [ pack('n', 1005), 'reserved Close status' ],
    [ pack('n', 1000) . "\xff", 'invalid UTF-8 Close reason' ],
) {
    my ($payload, $name) = @$case;

    my $server = Unblock::WebSocket::_Native->new('server', 1024);
    my $before = $server->_memory_used;

    my $events = $server->feed(masked_close($payload));
    is_deeply($events, [], "$name produces no application event");
    ok($server->_error_code, "$name records protocol error");

    my $wire = $server->flush;
    ok(length($wire), "$name produces protocol Close output");

    my $after = $server->_memory_used;
    is($after, $before, "$name leaves native heap use at baseline");
}

done_testing;
