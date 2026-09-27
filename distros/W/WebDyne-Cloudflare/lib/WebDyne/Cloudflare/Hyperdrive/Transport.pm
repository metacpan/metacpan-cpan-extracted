package WebDyne::Cloudflare::Hyperdrive::Transport;

use 5.020;
use strict;
use warnings;
use Future::AsyncAwait;
use JSON::PP ();
use WebDyne::Cloudflare ();
use WebDyne::Cloudflare::Hyperdrive::Codec;
use WebDyne::Cloudflare::Hyperdrive::Error;

our $VERSION='0.001';
our $HOST_CALL;
my $json_or=JSON::PP->new()->canonical();

sub new {
    my ($class, %opt)=@_;
    my $scope_hr=$opt{'scope'};
    die "Hyperdrive transport requires a PAGI scope\n" unless ref($scope_hr) eq 'HASH';
    my $extension_hr=(ref($scope_hr->{'extensions'}) eq 'HASH')
        ? $scope_hr->{'extensions'}{'webdyne.cloudflare.hyperdrive'} : undef;
    die "Missing or invalid Hyperdrive capability\n"
        unless (ref($extension_hr) eq 'HASH')&&defined($extension_hr->{'version'})
        &&!ref($extension_hr->{'version'})&&($extension_hr->{'version'} eq '1')
        &&defined($extension_hr->{'capability'})&&!ref($extension_hr->{'capability'})
        &&length($extension_hr->{'capability'})&&(ref($extension_hr->{'bindings'}) eq 'ARRAY');
    my $binding=$opt{'binding'}//'DB';
    die "Invalid Hyperdrive binding\n" unless !ref($binding)&&($binding=~/\A[A-Z_][A-Z0-9_]*\z/);
    die "Hyperdrive binding is unavailable\n"
        unless grep { defined($_)&&!ref($_)&&($_ eq $binding) } @{$extension_hr->{'bindings'}};
    return bless({ capability => $extension_hr->{'capability'}, binding => $binding }, $class);
}


async sub call {
    my ($self, $operation, %opt)=@_;
    die "Invalid Hyperdrive operation\n" unless defined($operation)&&!ref($operation)
        &&($operation=~/\A(?:open|query|begin|commit|rollback|disconnect)\z/);
    die "Cannot override Hyperdrive capability\n"
        if grep { exists($opt{$_}) } qw(version capability binding operation);
    my $wire_hr={ %opt, version => 1, capability => $self->{'capability'},
        binding => $self->{'binding'}, operation => $operation };
    $wire_hr=WebDyne::Cloudflare::json_value($wire_hr);
    my $wire=$json_or->encode($wire_hr);
    my $response;
    if ($HOST_CALL) { $response=$HOST_CALL->($wire) }
    else {
        no strict 'refs';
        my $host_cr=*{'WebDyne::Cloudflare::Hyperdrive::Transport::host_call'}{'CODE'};
        die "Hyperdrive host adapter is not registered\n" unless $host_cr;
        $response=$host_cr->($wire);
    }
    my $response_hr=eval { $json_or->decode($response) };
    die "Invalid Hyperdrive host response\n" unless (ref($response_hr) eq 'HASH')
        &&defined($response_hr->{'version'})&&!ref($response_hr->{'version'})
        &&($response_hr->{'version'} eq '1')&&JSON::PP::is_bool($response_hr->{'ok'});
    if (!$response_hr->{'ok'}) {
        my $error_hr=$response_hr->{'error'};
        die "Invalid Hyperdrive host error\n" unless ref($error_hr) eq 'HASH'
            &&defined($error_hr->{'message'})&&!ref($error_hr->{'message'});
        die WebDyne::Cloudflare::Hyperdrive::Error->new(%{$error_hr});
    }
    return WebDyne::Cloudflare::Hyperdrive::Codec::result($response_hr->{'result'});
}

1;
