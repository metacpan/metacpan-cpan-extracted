use strict;
use warnings;
use Test::More;

use Web3::Tiny::Keccak256 qw(keccak256 keccak256_hex);

# Known-good Keccak-256 (Ethereum flavor, 0x01 padding -- NOT NIST SHA3-256)
# digests. The empty-string and "abc" vectors are the commonly published
# Keccak-256 KATs; the rest were cross-checked against the independent
# Crypt::Digest::Keccak256 (CryptX) implementation and pin down padding at
# and around the 136-byte block boundary.
my @vectors = (
    [ ''                                             => 'c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470' ],
    [ 'abc'                                          => '4e03657aea45a94fc7d47ba826c8d667c0d1e6e33a64a036ec44f58fa12d6c45' ],
    [ 'The quick brown fox jumps over the lazy dog'  => '4d741b6f1eb29cb2a9b9911c82f56fa8d73b04959d3d9d222895df6c0b28aa15' ],
    [ 'The quick brown fox jumps over the lazy dog.' => '578951e24efd62a3d63a86f7cd19aaa53c898fe287d2552133220370240b572d' ],
    [ ('a' x 135)                                     => '34367dc248bbd832f4e3e69dfaac2f92638bd0bbd18f2912ba4ef454919cf446' ],
    [ ('a' x 136)                                     => 'a6c4d403279fe3e0af03729caada8374b5ca54d8065329a3ebcaeb4b60aa386e' ],
    [ ('a' x 137)                                     => 'd869f639c7046b4929fc92a4d988a8b22c55fbadb802c0c66ebcd484f1915f39' ],
    [ ('a' x 1000)                                     => 'b6a4ac1f51884d71f30fa397a5e155de3099e11fc0edef5d08b646e621e19de9' ],
);

for my $v (@vectors) {
    my ($msg, $expect) = @$v;
    my $label = length($msg) > 40 ? substr($msg, 0, 20) . '...(' . length($msg) . ' bytes)' : ($msg eq '' ? '(empty)' : $msg);

    is(keccak256_hex($msg), $expect, "keccak256_hex: $label");
    is(unpack('H*', keccak256($msg)), $expect, "keccak256 (raw bytes): $label");
}

is(keccak256_hex(), keccak256_hex(''), 'undef input treated as empty string');

done_testing;
