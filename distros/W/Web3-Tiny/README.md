# Web3::Tiny

A small, dependency-light way to talk to Ethereum (and other EVM chains) from Perl.

```perl
use Web3::Tiny;
use Web3::Tiny::Util qw(to_wei from_wei);

my $web3 = Web3::Tiny->new(rpc_url => 'https://ethereum-rpc.publicnode.com');

print $web3->block_number, "\n";
print from_wei($web3->get_balance('0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045')), " ETH\n";

my $weth = $web3->contract(
    address => '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2',
    abi     => {
        symbol    => { sig => 'symbol()',           returns => ['string']  },
        balanceOf => { sig => 'balanceOf(address)', returns => ['uint256'] },
    },
);
print $weth->call('symbol'), "\n";                       # WETH
print $weth->call('balanceOf', $web3_address), "\n";     # raw wei, as a Math::BigInt

# sign and send a transaction
my $wallet = $web3->wallet(private_key => '0x...');
my $erc20  = $web3->contract(
    address => '0x...',
    abi     => { transfer => { sig => 'transfer(address,uint256)', returns => ['bool'] } },
);
my $tx_hash = $erc20->send($wallet, 'transfer', $to_address, to_wei('1.5'));
```

## Why

A handful of CPAN modules already talk to Ethereum's JSON-RPC API --
[Net::Ethereum](https://metacpan.org/pod/Net::Ethereum),
[Ethereum::RPC::Client](https://metacpan.org/pod/Ethereum::RPC::Client),
and [Blockchain::Ethereum](https://metacpan.org/dist/Blockchain-Ethereum)
among them -- but each either predates modern Solidity ABI features (arrays,
full scalar-type coverage) or reinvents the crypto primitives by hand in
pure Perl. Web3::Tiny's crypto (`Web3::Tiny::Secp256k1`,
`Web3::Tiny::Keccak256`) is a thin wrapper around
[CryptX](https://metacpan.org/pod/CryptX), an XS module wrapping the
well-audited libtomcrypt C library, instead of a pure-Perl
reimplementation -- everything else (`Math::BigInt`, `HTTP::Tiny`,
`JSON::PP`) is Perl core.

```
cpanm CryptX
```

## What's in here

| Module                    | Purpose                                            |
|----------------------------|-----------------------------------------------------|
| `Web3::Tiny`               | Facade: connect, read balances/nonces, mint wallets/contracts |
| `Web3::Tiny::RPC`          | JSON-RPC 2.0 transport                             |
| `Web3::Tiny::ABI`          | Solidity ABI encode/decode + function selectors    |
| `Web3::Tiny::Wallet`       | Private key -> address, EIP-155 transaction signing |
| `Web3::Tiny::Contract`     | Bind an address + method list, `call`/`send`       |
| `Web3::Tiny::Secp256k1`    | secp256k1 ECDSA (sign/verify/recover), via CryptX  |
| `Web3::Tiny::Keccak256`    | Keccak-256 (Ethereum's flavor, not NIST SHA3), via CryptX |
| `Web3::Tiny::RLP`          | Recursive Length Prefix encoding                   |
| `Web3::Tiny::Util`         | `to_wei`/`from_wei` and hex/bigint helpers          |

## Scope

Supports the common Solidity ABI scalar types plus `T[]`/`T[k]` arrays of
them (no tuples/structs, no arrays-of-arrays), and legacy (pre-EIP-1559)
transactions with EIP-155 replay protection. Every primitive here has been
checked against known-good vectors (Ethereum wiki RLP examples, the
Solidity ABI spec's own worked example, EIP-55's checksum test vectors,
well-known ERC20 selectors, and live `eth_call`s against WETH on mainnet).

Not in scope for v0.01: EIP-1559 transactions, event log decoding, ENS.

## Installing

```
perl Makefile.PL
make
make test
make install
```

## Testing

```
prove -lv t/
```

Every module has its own test file (`t/NN-name.t`) checked against
known-good vectors rather than just round-tripping its own output:

| File                          | Covers                                                        |
|--------------------------------|----------------------------------------------------------------|
| `t/00-load.t`                   | Every module compiles and loads                                |
| `t/10-keccak256.t`              | `keccak256("")`/`"abc"` KATs, ERC20 selectors, event topic0    |
| `t/11-keccak256-vectors.t`      | Longer Keccak-256 vectors, incl. padding at/around the 136-byte block boundary |
| `t/20-secp256k1.t`              | ECDSA sign/verify/recover round-trips                          |
| `t/30-rlp.t`                    | Ethereum wiki RLP encoding examples                            |
| `t/40-abi.t`                    | Solidity ABI spec's own worked encode/decode example           |
| `t/50-wallet.t`                 | EIP-55 checksum vectors, EIP-155 signed-tx recovery            |
| `t/60-util.t`                   | `to_wei`/`from_wei` and hex/bigint helpers                     |

## Before uploading to CPAN

This is a fresh distribution that has not been published yet. Before
`cpan-upload`:

- Double check the module name isn't already taken: https://metacpan.org/search?q=Web3-Tiny
- Get a PAUSE account at https://pause.perl.org/ if you don't have one.

## License

Same terms as Perl itself.
