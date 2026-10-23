use strict;
use warnings;
use Test::More;

use Unblock::WebSocket::_Frame;

sub dies_like {
    my ($code, $pattern, $name) = @_;
    my $ok = eval { $code->(); 1 };
    my $error = $@;
    ok(!$ok, $name);
    like($error, $pattern, "$name reports expected error");
}

my $masked_hello = pack('H*', '818537fa213d7f9f4d5158');
is(
    Unblock::WebSocket::_Frame->encode(
        opcode   => 1,
        payload  => 'Hello',
        masked   => 1,
        mask_key => pack('H*', '37fa213d'),
    ),
    $masked_hello,
    'encoder matches RFC 6455 masked Hello vector',
);

is(
    Unblock::WebSocket::_Frame->encode(
        opcode  => 1,
        payload => 'Hello',
        masked  => 0,
    ),
    "\x81\x05Hello",
    'encoder creates unmasked server text frame',
);

my $server_parser = Unblock::WebSocket::_Frame->new_parser(
    expect_masked  => 1,
    max_frame_size => 1024,
);
$server_parser->input($masked_hello);
my $hello = $server_parser->next_frame;
is($hello->{type}, 'text', 'server parser identifies text frame');
is($hello->{payload}, 'Hello', 'server parser decodes RFC masked Hello');
ok(!defined($server_parser->next_frame), 'parser has no extra frame');

my $wire126 = Unblock::WebSocket::_Frame->encode(
    opcode   => 2,
    payload  => 'x' x 126,
    masked   => 1,
    mask_key => "\x01\x02\x03\x04",
);
is(ord(substr($wire126, 1, 1)) & 0x7f, 126,
    'encoder uses 16-bit length form at 126 bytes');

for my $split (1 .. length($wire126) - 1) {
    my $parser = Unblock::WebSocket::_Frame->new_parser(
        expect_masked  => 1,
        max_frame_size => 1024,
    );
    $parser->input(substr($wire126, 0, $split));
    ok(!defined($parser->next_frame), "frame incomplete at split $split");
    $parser->input(substr($wire126, $split));
    my $frame = $parser->next_frame;
    is($frame->{payload}, 'x' x 126, "frame completes after split $split");
}

my $client_parser = Unblock::WebSocket::_Frame->new_parser(
    expect_masked  => 0,
    max_frame_size => 1024,
);
$client_parser->input("\x81\x01a\x82\x01b");
is($client_parser->next_frame->{payload}, 'a',
    'parser returns first coalesced frame');
is($client_parser->next_frame->{payload}, 'b',
    'parser returns second coalesced frame');

dies_like(
    sub {
        my $parser = Unblock::WebSocket::_Frame->new_parser(
            expect_masked  => 1,
            max_frame_size => 1024,
        );
        $parser->input("\x81\x01x");
        $parser->next_frame;
    },
    qr/masking direction/i,
    'server rejects unmasked client frame',
);

dies_like(
    sub {
        my $parser = Unblock::WebSocket::_Frame->new_parser(
            expect_masked  => 0,
            max_frame_size => 1024,
        );
        $parser->input($masked_hello);
        $parser->next_frame;
    },
    qr/masking direction/i,
    'client rejects masked server frame',
);

for my $case (
    [ "\xc1\x00", qr/reserved RSV bits/i, 'RSV bits' ],
    [ "\x83\x00", qr/reserved opcode/i, 'reserved opcode' ],
    [ "\x09\x00", qr/control frame is fragmented/i, 'fragmented control frame' ],
    [ "\x89\x7e\x00\x7e", qr/control frame payload exceeds 125/i, 'long control frame' ],
    [ "\x82\x7e\x00\x7d", qr/non-minimal 16-bit/i, 'non-minimal 16-bit length' ],
    [ "\x82\x7f\x00\x00\x00\x00\x00\x00\xff\xff",
        qr/non-minimal 64-bit/i, 'non-minimal 64-bit length' ],
    [ "\x82\x7f\x80\x00\x00\x00\x00\x00\x00\x00",
        qr/reserved high bit/i, '64-bit high bit' ],
    [ "\x82\x7e\x04\x01", qr/exceeds configured limit/i, 'advertised size limit' ],
) {
    my ($wire, $pattern, $name) = @$case;
    dies_like(
        sub {
            my $parser = Unblock::WebSocket::_Frame->new_parser(
                expect_masked  => 0,
                max_frame_size => 1024,
            );
            $parser->input($wire);
            $parser->next_frame;
        },
        $pattern,
        "parser rejects $name",
    );
}

done_testing;
