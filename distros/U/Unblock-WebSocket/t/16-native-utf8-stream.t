use strict;
use warnings;
use Test::More;

use Unblock::WebSocket;
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

sub close_code {
    my ($wire) = @_;
    my $parser = Unblock::WebSocket::_Frame->new_parser(
        expect_masked  => 0,
        max_frame_size => 1024,
    );
    $parser->input($wire);
    while (my $frame = $parser->next_frame) {
        next unless $frame->{opcode} == 8;
        return unpack('n', substr($frame->{payload}, 0, 2));
    }
    return;
}

{
    my $server = Unblock::WebSocket::_Native->new('server', 1024);

    my $part1 = pack('H*', 'cebae1bdb9cf83cebcceb5f4');
    my $first = masked_frame(
        opcode   => 1,
        payload  => $part1,
        fin      => 0,
        mask_key => "\x01\x02\x03\x04",
    );
    my $second = masked_frame(
        opcode   => 0,
        payload  => "\x90",
        fin      => 0,
        mask_key => "\x05\x06\x07\x08",
    );

    is_deeply($server->feed($first), [],
        'incomplete UTF-8 sequence may span a fragment boundary');
    is($server->_error_code, 0,
        'first text fragment with incomplete sequence is accepted');

    is_deeply($server->feed($second), [],
        'invalid continuation fragment produces no application event');
    is($server->_error_string, 'BAD_UTF8',
        'invalid UTF-8 is rejected at the offending continuation fragment');
    is(close_code($server->flush), 1007,
        'fragment-boundary UTF-8 failure sends Close 1007');
}

{
    my $server = Unblock::WebSocket::_Native->new('server', 1024);

    my $part1 = pack('H*', 'cebae1bdb9cf83cebcceb5f4');
    my $payload = $part1 . "\x90\x80\x80edited";
    my $wire = masked_frame(
        opcode   => 1,
        payload  => $payload,
        fin      => 1,
        mask_key => "\x09\x0a\x0b\x0c",
    );

    my $header_size = 6;
    my $split = $header_size + length($part1);

    is_deeply($server->feed(substr($wire, 0, $split)), [],
        'partial text frame is accepted before offending octet arrives');
    is($server->_error_code, 0,
        'partial text frame has no premature UTF-8 error');

    is_deeply($server->feed(substr($wire, $split, 1)), [],
        'offending chopped octet produces no application event');
    is($server->_error_string, 'BAD_UTF8',
        'invalid UTF-8 is rejected immediately within a chopped frame');
    is(close_code($server->flush), 1007,
        'mid-frame UTF-8 failure sends Close 1007');
}

done_testing;
