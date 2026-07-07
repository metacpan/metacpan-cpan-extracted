use strict;
use warnings;
use Test::More;

use Web3::Tiny::Wallet;
use Web3::Tiny::Secp256k1 qw(recover_pubkey pubkey_to_address);
use Web3::Tiny::Keccak256 qw(keccak256);
use Web3::Tiny::RLP qw(rlp_encode int_to_bytes);

# official EIP-55 checksum test vectors
for my $addr (
    '0x5aAeb6053F3E94C9b9A09f33669435E7Ef1BeAed',
    '0xfB6916095ca1df60bB79Ce92cE3Ea74c37c5d359',
    '0xdbF03B407c01E7cD3CBea99509d93f8DDDC8C6FB',
    '0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb',
) {
    is(Web3::Tiny::Wallet::to_checksum_address(lc $addr), $addr, "EIP-55 checksum for $addr");
}

my $priv_hex = '0x' . ('11' x 32);
my $wallet   = Web3::Tiny::Wallet->new(private_key => $priv_hex);
like($wallet->address, qr/^0x[0-9a-fA-F]{40}$/, 'wallet address looks right shape');

my $to = '35' x 20;
my $raw = $wallet->sign_transaction(
    nonce     => 9,
    gas_price => '20000000000',
    gas       => 21000,
    to        => "0x$to",
    value     => '1000000000000000000',
    chain_id  => 1,
);
like($raw, qr/^0x[0-9a-f]+$/, 'sign_transaction returns hex string');

# the signature must recover to the wallet's own address
my @unsigned = (
    int_to_bytes(9), int_to_bytes('20000000000'), int_to_bytes(21000),
    pack('H*', $to), int_to_bytes('1000000000000000000'), '',
    int_to_bytes(1), '', '',
);
my $hash = keccak256(rlp_encode(\@unsigned));
my ($r, $s, $recid) = Web3::Tiny::Secp256k1::sign_hash($hash, pack('H*', '11' x 32));
my ($rx, $ry) = recover_pubkey($hash, $r, $s, $recid);
my $recovered_addr = '0x' . unpack('H*', pubkey_to_address($rx, $ry));
is(lc($recovered_addr), lc($wallet->address), 'signed tx recovers to wallet address');

done_testing;
