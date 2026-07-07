package Web3::Tiny::Keccak256;

use strict;
use warnings;
use Exporter 'import';
use Crypt::Digest::Keccak256 ();

our $VERSION   = '0.01';
our @EXPORT_OK = qw(keccak256 keccak256_hex);

# keccak256($bytes) -> 32 raw bytes
#
# Crypt::Digest::Keccak256 (part of CryptX) implements the original Keccak
# padding/domain separation (0x01), which is what Ethereum uses for function
# selectors, address derivation, and hashing in general -- NOT NIST SHA3-256
# (which uses a 0x06 domain separator and would give different digests).
sub keccak256 {
    my ($msg) = @_;
    $msg = '' unless defined $msg;
    return Crypt::Digest::Keccak256::keccak256($msg);
}

sub keccak256_hex {
    my ($msg) = @_;
    return unpack('H*', keccak256($msg));
}

1;

__END__

=head1 NAME

Web3::Tiny::Keccak256 - Keccak-256 (Ethereum flavor)

=head1 SYNOPSIS

    use Web3::Tiny::Keccak256 qw(keccak256 keccak256_hex);

    my $digest = keccak256("hello");        # 32 raw bytes
    my $hex    = keccak256_hex("hello");    # 64 hex chars

=head1 DESCRIPTION

Thin wrapper around L<Crypt::Digest::Keccak256> (part of L<CryptX>, an XS
module wrapping libtomcrypt) using the original Keccak padding/domain
separation (0x01), which is what Ethereum uses for function selectors,
address derivation, and hashing in general -- I<not> NIST SHA3-256 (which
uses a 0x06 domain separator and would give different digests).

=cut
