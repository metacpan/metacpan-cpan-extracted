use strict;
use warnings;
use Test::More;

use Unblock::WebSocket::_UTF8;

my %valid = (
    ascii        => [ '41',       0x41 ],
    two_byte     => [ 'c280',     0x80 ],
    three_byte   => [ 'e0a080',   0x800 ],
    nonchar_fffe => [ 'efbfbe',   0xfffe ],
    nonchar_ffff => [ 'efbfbf',   0xffff ],
    four_byte    => [ 'f0908080', 0x10000 ],
    max_scalar   => [ 'f48fbfbf', 0x10ffff ],
);

for my $name (sort keys %valid) {
    my ($hex, $codepoint) = @{$valid{$name}};
    my $bytes = pack('H*', $hex);

    ok(Unblock::WebSocket::_UTF8->valid_bytes($bytes),
        "$name is valid RFC 3629 UTF-8");

    my $decoded = Unblock::WebSocket::_UTF8->decode($bytes);
    is(ord($decoded), $codepoint, "$name decodes to expected code point");

    my $encoded = Unblock::WebSocket::_UTF8->encode($decoded);
    is(unpack('H*', $encoded), $hex, "$name round-trips through Perl text");
}

my %invalid = (
    lone_continuation => '80',
    overlong_nul      => 'c080',
    short_two_byte    => 'c2',
    overlong_three    => 'e08080',
    surrogate         => 'eda080',
    short_three       => 'e282',
    overlong_four     => 'f0808080',
    above_unicode     => 'f4908080',
    short_four        => 'f09080',
    illegal_lead      => 'f5',
);

for my $name (sort keys %invalid) {
    my $bytes = pack('H*', $invalid{$name});
    ok(!Unblock::WebSocket::_UTF8->valid_bytes($bytes),
        "$name is rejected");
    my $ok = eval { Unblock::WebSocket::_UTF8->decode($bytes); 1 };
    ok(!$ok, "$name decode dies");
}

for my $codepoint (0xd800, 0xdfff, 0x110000) {
    my $text = chr($codepoint);
    my $ok = eval { Unblock::WebSocket::_UTF8->encode($text); 1 };
    ok(!$ok, sprintf('U+%X is rejected as application text', $codepoint));
}

done_testing;
