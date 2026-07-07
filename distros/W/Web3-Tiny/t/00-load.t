use strict;
use warnings;
use Test::More;

use_ok($_) for qw(
    Web3::Tiny
    Web3::Tiny::RPC
    Web3::Tiny::ABI
    Web3::Tiny::RLP
    Web3::Tiny::Wallet
    Web3::Tiny::Contract
    Web3::Tiny::Secp256k1
    Web3::Tiny::Keccak256
    Web3::Tiny::Util
);

done_testing;
