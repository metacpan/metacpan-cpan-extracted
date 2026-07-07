package Web3::Tiny::RPC;

use strict;
use warnings;
use HTTP::Tiny;
use JSON::PP qw(encode_json decode_json);

our $VERSION = '0.01';

sub new {
    my ($class, %opts) = @_;
    die "Web3::Tiny::RPC: 'url' is required\n" unless $opts{url};

    my $self = {
        url     => $opts{url},
        _id     => 0,
        _http   => HTTP::Tiny->new(
            timeout         => $opts{timeout} || 30,
            agent           => 'Web3-Tiny/' . $VERSION,
            default_headers => { 'Content-Type' => 'application/json' },
        ),
    };
    return bless $self, $class;
}

# call($method, @params) -> $result (already JSON-decoded)
# dies on transport failure or a JSON-RPC "error" response.
sub call {
    my ($self, $method, @params) = @_;

    my $body = encode_json({
        jsonrpc => '2.0',
        id      => ++$self->{_id},
        method  => $method,
        params  => [@params],
    });

    my $resp = $self->{_http}->post(
        $self->{url},
        { content => $body },
    );

    die "Web3::Tiny::RPC: HTTP request to $self->{url} failed: $resp->{status} $resp->{reason}\n"
        unless $resp->{success};

    my $decoded = eval { decode_json($resp->{content}) };
    die "Web3::Tiny::RPC: invalid JSON response: $@\n" if $@;

    if (my $err = $decoded->{error}) {
        my $msg  = $err->{message} // 'unknown error';
        my $code = $err->{code}    // '?';
        die "Web3::Tiny::RPC: $method failed [$code]: $msg\n";
    }

    return $decoded->{result};
}

1;

__END__

=head1 NAME

Web3::Tiny::RPC - Minimal JSON-RPC 2.0 client for Ethereum nodes

=head1 SYNOPSIS

    use Web3::Tiny::RPC;

    my $rpc = Web3::Tiny::RPC->new(url => 'https://eth.llamarpc.com');
    my $block_number = $rpc->call('eth_blockNumber');

=head1 DESCRIPTION

Thin wrapper over L<HTTP::Tiny> + L<JSON::PP> (both Perl core) that
speaks JSON-RPC 2.0 to any standard Ethereum JSON-RPC endpoint.
C<call()> dies on transport errors or JSON-RPC error responses.

=cut
