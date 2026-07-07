use strict;
use warnings;
use Test::More;

use Web3::Tiny::Keccak256 qw(keccak256_hex);

is(keccak256_hex(''), 'c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470',
    'keccak256("") matches Ethereum EMPTY_CODE_HASH');

is(keccak256_hex('abc'), '4e03657aea45a94fc7d47ba826c8d667c0d1e6e33a64a036ec44f58fa12d6c45',
    'keccak256("abc")');

my %selectors = (
    'transfer(address,uint256)'             => 'a9059cbb',
    'transferFrom(address,address,uint256)' => '23b872dd',
    'approve(address,uint256)'              => '095ea7b3',
    'balanceOf(address)'                    => '70a08231',
    'totalSupply()'                         => '18160ddd',
    'symbol()'                              => '95d89b41',
    'decimals()'                            => '313ce567',
);
for my $sig (sort keys %selectors) {
    is(substr(keccak256_hex($sig), 0, 8), $selectors{$sig}, "selector for $sig");
}

is(keccak256_hex('Transfer(address,address,uint256)'),
    'ddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef',
    'ERC20 Transfer event topic0');

done_testing;
