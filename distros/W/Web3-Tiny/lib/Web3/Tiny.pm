package Web3::Tiny;

use strict;
use warnings;

use Web3::Tiny::RPC;
use Web3::Tiny::Wallet;
use Web3::Tiny::Contract;
use Web3::Tiny::Util qw(hex_to_bigint);

our $VERSION = '0.01';

# Web3::Tiny->new(rpc_url => 'https://...')
sub new {
    my ($class, %opts) = @_;
    die "Web3::Tiny: 'rpc_url' is required\n" unless $opts{rpc_url};

    return bless {
        rpc => Web3::Tiny::RPC->new(url => $opts{rpc_url}, timeout => $opts{timeout}),
    }, $class;
}

sub rpc { return $_[0]->{rpc} }

# wallet(private_key => '0x...') -> Web3::Tiny::Wallet
sub wallet {
    my ($self, %opts) = @_;
    return Web3::Tiny::Wallet->new(%opts);
}

# contract(address => '0x...', abi => { ... }) -> Web3::Tiny::Contract
sub contract {
    my ($self, %opts) = @_;
    return Web3::Tiny::Contract->new(%opts, rpc => $self->{rpc});
}

# get_balance('0x...') -> Math::BigInt (wei)
sub get_balance {
    my ($self, $address) = @_;
    return hex_to_bigint($self->{rpc}->call('eth_getBalance', $address, 'latest'));
}

# transaction_count('0x...') -> Math::BigInt (nonce)
sub transaction_count {
    my ($self, $address) = @_;
    return hex_to_bigint($self->{rpc}->call('eth_getTransactionCount', $address, 'latest'));
}

# gas_price() -> Math::BigInt (wei)
sub gas_price {
    my ($self) = @_;
    return hex_to_bigint($self->{rpc}->call('eth_gasPrice'));
}

# chain_id() -> Math::BigInt
sub chain_id {
    my ($self) = @_;
    return hex_to_bigint($self->{rpc}->call('eth_chainId'));
}

# block_number() -> Math::BigInt
sub block_number {
    my ($self) = @_;
    return hex_to_bigint($self->{rpc}->call('eth_blockNumber'));
}

# send_raw_transaction('0x...') -> '0x...' transaction hash
sub send_raw_transaction {
    my ($self, $raw_tx) = @_;
    return $self->{rpc}->call('eth_sendRawTransaction', $raw_tx);
}

# transaction_receipt('0x...') -> hashref or undef if not yet mined
sub transaction_receipt {
    my ($self, $tx_hash) = @_;
    return $self->{rpc}->call('eth_getTransactionReceipt', $tx_hash);
}

1;

__END__

=head1 NAME

Web3::Tiny - A small, dependency-light way to talk to Ethereum from Perl

=head1 SYNOPSIS

    use Web3::Tiny;
    use Web3::Tiny::Util qw(to_wei from_wei);

    my $web3 = Web3::Tiny->new(rpc_url => 'https://ethereum-rpc.publicnode.com');

    print $web3->block_number, "\n";
    print from_wei($web3->get_balance('0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045')), " ETH\n";

    # --- read from a contract ---
    my $weth = $web3->contract(
        address => '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2',
        abi     => {
            symbol    => { sig => 'symbol()',           returns => ['string']  },
            balanceOf => { sig => 'balanceOf(address)', returns => ['uint256'] },
        },
    );
    print $weth->call('symbol'), "\n";
    print $weth->call('balanceOf', '0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045'), "\n";

    # --- sign and send a transaction ---
    my $wallet = $web3->wallet(private_key => '0x...');
    my $erc20  = $web3->contract(
        address => '0x...',
        abi     => { transfer => { sig => 'transfer(address,uint256)', returns => ['bool'] } },
    );
    my $tx_hash = $erc20->send($wallet, 'transfer', $to_address, to_wei('1.5'));

=head1 DESCRIPTION

Web3::Tiny is a minimal Ethereum toolkit: JSON-RPC transport, Solidity
ABI encoding/decoding, secp256k1/Keccak256/RLP for signing legacy
transactions, and thin wrappers for calling and sending to contracts.

Transport and encoding (L<HTTP::Tiny>, L<JSON::PP>, L<Math::BigInt>) are
Perl core. The cryptography -- secp256k1/ECDSA and Keccak-256 (see
L<Web3::Tiny::Secp256k1> and L<Web3::Tiny::Keccak256>) -- is a thin
wrapper around L<CryptX>, an XS module wrapping the well-audited
libtomcrypt C library, rather than a hand-rolled implementation.

=head2 Scope

This is intentionally small. It supports:

=over 4

=item * The common Solidity ABI scalar types, plus C<T[]>/C<T[k]> arrays of them (no tuples/structs, no arrays-of-arrays)

=item * Legacy (pre-EIP-1559) transactions with EIP-155 replay protection

=item * EIP-55 checksummed addresses

=back

It does not implement EIP-1559 transactions, event log filter/decoding
helpers, or ENS resolution. Patches welcome.

=head1 SEE ALSO

L<Web3::Tiny::RPC>, L<Web3::Tiny::ABI>, L<Web3::Tiny::Wallet>,
L<Web3::Tiny::Contract>, L<Web3::Tiny::Secp256k1>,
L<Web3::Tiny::Keccak256>, L<Web3::Tiny::RLP>, L<Web3::Tiny::Util>

=head1 AUTHOR

Alex Pepper E<lt>axpepper@gmail.comE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
