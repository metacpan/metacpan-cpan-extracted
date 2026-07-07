package Web3::Tiny::Contract;

use strict;
use warnings;

use Web3::Tiny::ABI qw(encode_call decode_result);

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

# Web3::Tiny::Contract->new(
#     rpc     => $rpc,               # a Web3::Tiny::RPC
#     address => '0x...',
#     abi     => {
#         balanceOf => { sig => 'balanceOf(address)', returns => ['uint256'] },
#         transfer  => { sig => 'transfer(address,uint256)', returns => ['bool'] },
#     },
# )
sub new {
    my ($class, %opts) = @_;
    for my $req (qw(rpc address abi)) {
        die "Web3::Tiny::Contract: '$req' is required\n" unless $opts{$req};
    }
    return bless {
        rpc     => $opts{rpc},
        address => $opts{address},
        abi     => $opts{abi},
    }, $class;
}

sub _method {
    my ($self, $name) = @_;
    my $m = $self->{abi}{$name};
    die "Web3::Tiny::Contract: unknown method '$name'\n" unless $m;
    return $m;
}

# call($method, @args) -> decoded return value(s) (a single scalar if
# only one return type, otherwise a list)
sub call {
    my ($self, $method, @args) = @_;
    my $m    = $self->_method($method);
    my $data = encode_call($m->{sig}, @args);

    my $result_hex = $self->{rpc}->call(
        'eth_call',
        { to => $self->{address}, data => '0x' . unpack('H*', $data) },
        'latest',
    );

    my $returns = $m->{returns} || [];
    return () unless @$returns;

    my @decoded = decode_result($returns, _hex_to_bytes($result_hex));
    return wantarray ? @decoded : $decoded[0];
}

# send($wallet, $method, @args, \%tx_opts) -> "0x..." transaction hash
#
# %tx_opts may supply nonce/gas_price/gas/chain_id/value explicitly;
# any left out are looked up from the node (nonce, gas_price, chain_id)
# or estimated (gas).
sub send {
    my $self   = shift;
    my $wallet = shift;
    my $method = shift;
    my %tx_opts = ref($_[-1]) eq 'HASH' ? %{ pop @_ } : ();
    my @args    = @_;

    my $m    = $self->_method($method);
    my $data = encode_call($m->{sig}, @args);
    my $data_hex = '0x' . unpack('H*', $data);

    my $rpc = $self->{rpc};

    $tx_opts{nonce} = do {
        my $n = $rpc->call('eth_getTransactionCount', $wallet->address, 'latest');
        hex($n);
    } unless defined $tx_opts{nonce};

    $tx_opts{gas_price} = do {
        my $gp = $rpc->call('eth_gasPrice');
        hex($gp);
    } unless defined $tx_opts{gas_price};

    $tx_opts{chain_id} = do {
        my $cid = $rpc->call('eth_chainId');
        hex($cid);
    } unless defined $tx_opts{chain_id};

    $tx_opts{gas} = do {
        my $est = $rpc->call('eth_estimateGas', {
            from => $wallet->address,
            to   => $self->{address},
            data => $data_hex,
            ( defined $tx_opts{value} ? (value => sprintf('0x%s', _to_hex($tx_opts{value}))) : () ),
        });
        hex($est);
    } unless defined $tx_opts{gas};

    my $raw = $wallet->sign_transaction(
        %tx_opts,
        to   => $self->{address},
        data => $data_hex,
    );

    return $rpc->call('eth_sendRawTransaction', $raw);
}

sub _to_hex {
    my ($n) = @_;
    require Math::BigInt;
    my $bi = ref($n) && $n->isa('Math::BigInt') ? $n : Math::BigInt->new("$n");
    my $hex = $bi->as_hex;
    $hex =~ s/^0x//;
    return $hex;
}

1;

__END__

=head1 NAME

Web3::Tiny::Contract - Bind a Solidity contract's ABI to a live address

=head1 SYNOPSIS

    my $erc20 = Web3::Tiny::Contract->new(
        rpc     => $rpc,
        address => '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2',    # WETH
        abi     => {
            symbol    => { sig => 'symbol()',              returns => ['string']  },
            balanceOf => { sig => 'balanceOf(address)',    returns => ['uint256'] },
            transfer  => { sig => 'transfer(address,uint256)', returns => ['bool'] },
        },
    );

    my $symbol = $erc20->call('symbol');
    my $bal    = $erc20->call('balanceOf', $wallet->address);

    my $tx_hash = $erc20->send($wallet, 'transfer', $to_address, '1000000000000000000');

=head1 DESCRIPTION

A deliberately small alternative to parsing full Solidity JSON ABIs:
you describe just the methods you actually call, each as a canonical
signature string plus its return types. C<call()> runs a read-only
C<eth_call> and decodes the result; C<send()> builds, signs (via a
L<Web3::Tiny::Wallet>), and broadcasts a transaction, auto-filling
nonce/gas price/chain id/gas estimate from the node when not supplied.

=cut
