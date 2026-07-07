package Web3::Tiny::Secp256k1;

use strict;
use warnings;
use Exporter 'import';
use Crypt::PK::ECC;
use Math::BigInt try => 'GMP,Pari';

use Web3::Tiny::Keccak256 qw(keccak256);

our $VERSION   = '0.01';
our @EXPORT_OK = qw(
    privkey_to_pubkey pubkey_to_address privkey_to_address
    sign_hash recover_pubkey verify_hash
);

# secp256k1 group order (as used by Bitcoin and Ethereum), needed only for
# the low-S normalization required by Ethereum since EIP-2 / Homestead.
my $N = Math::BigInt->new('0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141');
my $HALF_N = $N->copy->bsub(1)->bdiv(2);

sub _bytes_to_bi {
    my ($bytes) = @_;
    return Math::BigInt->from_hex('0x' . unpack('H*', $bytes));
}

sub _bi_to_bytes {
    my ($bi, $len) = @_;
    my $hex = $bi->as_hex;
    $hex =~ s/^0x//;
    $hex = '0' . $hex if length($hex) % 2;
    my $bytes = pack('H*', $hex);
    $bytes = ("\x00" x ($len - length($bytes))) . $bytes if length($bytes) < $len;
    return $bytes;
}

# privkey_to_pubkey($privkey_bytes) -> ($x_bytes32, $y_bytes32)
sub privkey_to_pubkey {
    my ($priv_bytes) = @_;
    my $pk = Crypt::PK::ECC->new;
    eval { $pk->import_key_raw($priv_bytes, 'secp256k1') };
    die "Web3::Tiny::Secp256k1: private key out of range\n" if $@;

    my $pub = $pk->export_key_raw('public');    # 0x04 || X(32) || Y(32)
    return (substr($pub, 1, 32), substr($pub, 33, 32));
}

# pubkey_to_address($x_bytes32, $y_bytes32) -> 20 raw bytes
sub pubkey_to_address {
    my ($x, $y) = @_;
    my $hash = keccak256($x . $y);
    return substr($hash, 12, 20);
}

sub privkey_to_address {
    my ($priv_bytes) = @_;
    my ($x, $y) = privkey_to_pubkey($priv_bytes);
    return pubkey_to_address($x, $y);
}

# sign_hash($hash32_bytes, $priv_bytes) -> ($r_bytes32, $s_bytes32, $recid)
#
# RFC 6979 deterministic (HMAC-SHA256 nonce), normalized to low-s form
# (s <= N/2) as required by Ethereum since EIP-2 / Homestead. CryptX signs
# but does not itself enforce low-s, so that normalization happens here.
sub sign_hash {
    my ($hash, $priv_bytes) = @_;
    die "Web3::Tiny::Secp256k1: hash must be 32 bytes\n" unless length($hash) == 32;

    my $pk = Crypt::PK::ECC->new;
    eval { $pk->import_key_raw($priv_bytes, 'secp256k1') };
    die "Web3::Tiny::Secp256k1: private key out of range\n" if $@;

    my $sig = $pk->sign_hash_eth($hash, 'SHA256');
    my $r      = substr($sig, 0, 32);
    my $s      = substr($sig, 32, 32);
    my $recid  = unpack('C', substr($sig, 64, 1)) - 27;

    my $s_bi = _bytes_to_bi($s);
    if ($s_bi->bcmp($HALF_N) > 0) {
        $s     = _bi_to_bytes($N->copy->bsub($s_bi), 32);
        $recid ^= 1;
    }

    return ($r, $s, $recid);
}

# recover_pubkey($hash32, $r_bytes32, $s_bytes32, $recid) -> ($x_bytes32, $y_bytes32)
sub recover_pubkey {
    my ($hash, $r_bytes, $s_bytes, $recid) = @_;

    my $sig = $r_bytes . $s_bytes . pack('C', 27 + $recid);

    # recovery_pub_eth needs a curve context to recover into; the private
    # key generated here is discarded immediately, only its curve sticks.
    my $pk = Crypt::PK::ECC->new;
    $pk->generate_key('secp256k1');
    eval { $pk->recovery_pub_eth($sig, $hash) };
    die "Web3::Tiny::Secp256k1: invalid recovery id\n" if $@;

    my $pub = $pk->export_key_raw('public');
    return (substr($pub, 1, 32), substr($pub, 33, 32));
}

sub verify_hash {
    my ($hash, $r_bytes, $s_bytes, $pub_x, $pub_y) = @_;

    my $pk = Crypt::PK::ECC->new;
    eval { $pk->import_key_raw("\x04" . $pub_x . $pub_y, 'secp256k1') };
    return 0 if $@;

    # the recovery-id byte is irrelevant to verification, only to recovery
    my $sig = $r_bytes . $s_bytes . "\x1b";
    return $pk->verify_hash_eth($sig, $hash) ? 1 : 0;
}

1;

__END__

=head1 NAME

Web3::Tiny::Secp256k1 - secp256k1 ECDSA (Ethereum/Bitcoin curve)

=head1 SYNOPSIS

    use Web3::Tiny::Secp256k1 qw(privkey_to_address sign_hash recover_pubkey);

    my $priv = pack('H*', '00' x 31 . '01');   # 32-byte private key
    my $addr = privkey_to_address($priv);      # 20 raw bytes

    my ($r, $s, $recid) = sign_hash($hash32, $priv);

=head1 DESCRIPTION

Thin wrapper around L<Crypt::PK::ECC> (part of L<CryptX>, an XS module
wrapping libtomcrypt) for the secp256k1 elliptic curve, using CryptX's
built-in RFC 6979 deterministic nonce generation and Ethereum-flavored
signature format (C<sign_hash_eth>/C<verify_hash_eth>/C<recovery_pub_eth>).
Signatures are normalized to low-S form as required by Ethereum.

=cut
