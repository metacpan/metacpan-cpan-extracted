package WebDyne::Cloudflare::SecretsStore;

use 5.020;
use strict;
use warnings;
use Future::AsyncAwait;
use JSON::PP ();
use WebDyne::Cloudflare::SecretsStore::Error;

our $VERSION='0.001';
our $HOST_CALL;

use constant EXTENSION_NAME => 'webdyne.cloudflare.secrets_store';
use constant PROTOCOL_VERSION => 1;

my $json_or=JSON::PP->new()->canonical()->allow_nonref();

sub new {
    my ($class, %opt)=@_;
    my $scope_hr=$opt{'scope'};
    die "WebDyne::Cloudflare::SecretsStore requires a PAGI scope hash\n"
        unless ref($scope_hr) eq 'HASH';
    my $extension_hr=(ref($scope_hr->{'extensions'}) eq 'HASH')
        ? $scope_hr->{'extensions'}{EXTENSION_NAME()}
        : undef;
    die "PAGI scope has no " . EXTENSION_NAME() . " capability\n"
        unless ref($extension_hr) eq 'HASH';
    die "Unsupported SecretsStore capability protocol\n"
        unless (defined($extension_hr->{'version'})
            &&!ref($extension_hr->{'version'})
            &&($extension_hr->{'version'} eq PROTOCOL_VERSION()));
    die "Invalid SecretsStore capability token\n"
        unless (defined($extension_hr->{'capability'})
            &&!ref($extension_hr->{'capability'})
            &&length($extension_hr->{'capability'}));

    my $binding=(defined($opt{'binding'}) ? $opt{'binding'} : 'SECRET');
    die "Invalid SecretsStore binding name '$binding'\n"
        unless (!ref($binding)&&($binding=~/\A[A-Z_][A-Z0-9_]*\z/));
    my $bindings_ar=$extension_hr->{'bindings'};
    die "Invalid SecretsStore capability binding list\n"
        unless (ref($bindings_ar) eq 'ARRAY');
    my %binding=map { $_ => 1 } grep { defined($_)&&!ref($_) } @{$bindings_ar};
    die "SecretsStore binding '$binding' is not available to this request\n"
        unless $binding{$binding};

    my $self=bless({
        binding    => $binding,
        capability => $extension_hr->{'capability'},
    }, $class);
    return $self;
}


sub binding { return shift()->{'binding'}; }


async sub get {
    my ($self, @arg)=@_;
    die "SecretsStore get accepts no arguments\n" if @arg;
    my $wire=$json_or->encode({
        version    => PROTOCOL_VERSION,
        capability => $self->{'capability'},
        binding    => $self->{'binding'},
        operation  => 'get',
    });
    my $response_wire;
    my $called=eval { $response_wire=call_host($wire); 1 };
    die WebDyne::Cloudflare::SecretsStore::Error->new(name => 'SECRETS_STORE_HOST_ERROR')
        unless $called;
    my $response_hr=eval { $json_or->decode($response_wire) };
    die WebDyne::Cloudflare::SecretsStore::Error->new(name => 'SECRETS_STORE_PROTOCOL_ERROR')
        unless ((ref($response_hr) eq 'HASH')&&JSON::PP::is_bool($response_hr->{'ok'}));
    unless ($response_hr->{'ok'}) {
        my $error_hr=(ref($response_hr->{'error'}) eq 'HASH') ? $response_hr->{'error'} : {};
        die WebDyne::Cloudflare::SecretsStore::Error->new(name => $error_hr->{'name'});
    }
    die WebDyne::Cloudflare::SecretsStore::Error->new(name => 'SECRETS_STORE_PROTOCOL_ERROR')
        unless (defined($response_hr->{'result'})&&!ref($response_hr->{'result'}));
    return $response_hr->{'result'};
}


sub call_host {
    my ($wire)=@_;
    return $HOST_CALL->($wire) if $HOST_CALL;
    no strict 'refs';
    my $host_call_cr=*{'WebDyne::Cloudflare::SecretsStore::Host::call'}{'CODE'};
    die "SecretsStore host adapter is not registered in this runtime\n" unless $host_call_cr;
    return $host_call_cr->($wire);
}

1;
