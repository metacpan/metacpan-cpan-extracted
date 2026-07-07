package Web3::Tiny::RLP;

use strict;
use warnings;
use Exporter 'import';
use Math::BigInt;

our $VERSION   = '0.01';
our @EXPORT_OK = qw(rlp_encode int_to_bytes);

# int_to_bytes($n) -> minimal big-endian byte string (raw), with 0 => ''
# $n may be a plain non-negative integer, a decimal/hex string, or a
# Math::BigInt object.
sub int_to_bytes {
    my ($n) = @_;
    my $bi = ref($n) && $n->isa('Math::BigInt') ? $n->copy : Math::BigInt->new("$n");
    return '' if $bi->is_zero;

    my $hex = $bi->as_hex;
    $hex =~ s/^0x//;
    $hex = '0' . $hex if length($hex) % 2;
    return pack('H*', $hex);
}

# rlp_encode($item) -> raw RLP-encoded byte string
#
# $item is either:
#   - a plain scalar: treated as a raw byte string (NOT a decimal number --
#     convert integers with int_to_bytes() first)
#   - an array ref: treated as an RLP list, encoded recursively
sub rlp_encode {
    my ($item) = @_;

    if (ref($item) eq 'ARRAY') {
        my $payload = join '', map { rlp_encode($_) } @$item;
        return _with_length_prefix($payload, 0xc0, 0xf7);
    }

    my $str = defined($item) ? $item : '';
    if (length($str) == 1 && ord($str) <= 0x7f) {
        return $str;
    }
    return _with_length_prefix($str, 0x80, 0xb7);
}

sub _with_length_prefix {
    my ($payload, $short_base, $long_base) = @_;
    my $len = length($payload);

    if ($len <= 55) {
        return chr($short_base + $len) . $payload;
    }

    my $len_bytes = int_to_bytes($len);
    return chr($long_base + length($len_bytes)) . $len_bytes . $payload;
}

1;

__END__

=head1 NAME

Web3::Tiny::RLP - Recursive Length Prefix encoding for Ethereum

=head1 SYNOPSIS

    use Web3::Tiny::RLP qw(rlp_encode int_to_bytes);

    my $encoded = rlp_encode([
        int_to_bytes(9),        # nonce
        int_to_bytes(20e9),     # gas price
        int_to_bytes(21000),    # gas limit
        pack('H*', 'a1b2...'),  # to address, 20 raw bytes
        int_to_bytes(1e18),     # value
        '',                     # data
    ]);

=head1 DESCRIPTION

Minimal implementation of Ethereum's RLP encoding, used to serialize
transactions before signing/broadcasting.

=cut
