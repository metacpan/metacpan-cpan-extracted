package Web3::Tiny::Wallet;

use strict;
use warnings;

use Web3::Tiny::Secp256k1 qw(privkey_to_pubkey pubkey_to_address sign_hash);
use Web3::Tiny::Keccak256 qw(keccak256);
use Web3::Tiny::RLP       qw(rlp_encode int_to_bytes);

our $VERSION = '0.01';

sub _hex_to_bytes {
    my ($val) = @_;
    return '' unless defined $val && length($val);
    if ($val =~ /^0x([0-9a-fA-F]*)$/) {
        my $hex = $1;
        $hex = '0' . $hex if length($hex) % 2;
        return pack('H*', $hex);
    }
    return $val;
}

sub _strip_leading_zeros {
    my ($bytes) = @_;
    $bytes =~ s/^\x00+//;
    return $bytes;
}

# Web3::Tiny::Wallet->new(private_key => '0x...' or 32 raw bytes)
sub new {
    my ($class, %opts) = @_;
    die "Web3::Tiny::Wallet: 'private_key' is required\n" unless defined $opts{private_key};

    my $priv = _hex_to_bytes($opts{private_key});
    die "Web3::Tiny::Wallet: private_key must be 32 bytes\n" unless length($priv) == 32;

    my ($x, $y) = privkey_to_pubkey($priv);
    my $addr = pubkey_to_address($x, $y);

    return bless {
        priv    => $priv,
        pub_x   => $x,
        pub_y   => $y,
        address => $addr,
    }, $class;
}

# address() -> "0x" + EIP-55 checksummed 40-hex-char address
sub address {
    my ($self) = @_;
    return to_checksum_address($self->{address});
}

# to_checksum_address($addr) -- accepts "0x..." hex or 20 raw bytes
sub to_checksum_address {
    my ($addr) = @_;
    my $bytes = (length($addr) == 20) ? $addr : _hex_to_bytes($addr);
    my $hex   = lc unpack('H*', $bytes);
    my $hash  = unpack('H*', keccak256($hex));

    my $out = '';
    for my $i (0 .. length($hex) - 1) {
        my $c = substr($hex, $i, 1);
        if ($c =~ /[a-f]/ && hex(substr($hash, $i, 1)) >= 8) {
            $out .= uc $c;
        }
        else {
            $out .= $c;
        }
    }
    return '0x' . $out;
}

# sign_transaction(%tx) -> "0x..." raw signed legacy (EIP-155) transaction
#
# Required: nonce, gas_price, gas, chain_id
# Optional: to (omit/empty for contract creation), value (default 0),
#           data (default ''; raw bytes or "0x..." hex)
#
# Pass large numeric fields (gas_price, value) as decimal strings or
# Math::BigInt objects if they might exceed ~2^53 -- Perl numeric
# literals like 1e18 are floats and will silently lose precision.
sub sign_transaction {
    my ($self, %tx) = @_;

    for my $req (qw(nonce gas_price gas chain_id)) {
        die "Web3::Tiny::Wallet: '$req' is required\n" unless defined $tx{$req};
    }

    my $to_bytes = defined($tx{to}) && length($tx{to}) ? _hex_to_bytes($tx{to}) : '';
    die "Web3::Tiny::Wallet: 'to' must be 20 bytes\n"
        if length($to_bytes) && length($to_bytes) != 20;

    my $data = defined($tx{data}) ? _hex_to_bytes($tx{data}) : '';
    my $value = $tx{value} // 0;

    my @unsigned = (
        int_to_bytes($tx{nonce}),
        int_to_bytes($tx{gas_price}),
        int_to_bytes($tx{gas}),
        $to_bytes,
        int_to_bytes($value),
        $data,
        int_to_bytes($tx{chain_id}),
        '',
        '',
    );

    my $hash = keccak256(rlp_encode(\@unsigned));
    my ($r, $s, $recid) = sign_hash($hash, $self->{priv});
    my $v = $tx{chain_id} * 2 + 35 + $recid;

    my @signed = (
        int_to_bytes($tx{nonce}),
        int_to_bytes($tx{gas_price}),
        int_to_bytes($tx{gas}),
        $to_bytes,
        int_to_bytes($value),
        $data,
        int_to_bytes($v),
        _strip_leading_zeros($r),
        _strip_leading_zeros($s),
    );

    return '0x' . unpack('H*', rlp_encode(\@signed));
}

1;

__END__

=head1 NAME

Web3::Tiny::Wallet - Private key handling and transaction signing

=head1 SYNOPSIS

    use Web3::Tiny::Wallet;

    my $wallet = Web3::Tiny::Wallet->new(private_key => '0x' . ('11' x 32));
    print $wallet->address, "\n";    # EIP-55 checksummed

    my $raw_tx = $wallet->sign_transaction(
        nonce     => 0,
        gas_price => '20000000000',
        gas       => 21000,
        to        => '0x5B38Da6a701c568545dCfcB03FcB875f56beddC4',
        value     => '1000000000000000000',
        chain_id  => 1,
    );
    # broadcast $raw_tx via eth_sendRawTransaction

=head1 DESCRIPTION

Signs legacy (pre-EIP-1559) Ethereum transactions with EIP-155 replay
protection. EIP-1559 (type-2) transactions are not supported in this
release -- legacy transactions are accepted on every EVM chain, so this
covers the common case.

=cut
