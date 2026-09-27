package WebDyne::Cloudflare::SecretsStore::Error;

use 5.020;
use strict;
use warnings;
use overload '""' => 'as_string', fallback => 1;

our $VERSION='0.001';

my %message=(
    SECRETS_STORE_ERROR            => 'Secrets Store request failed',
    SECRETS_STORE_HOST_ERROR       => 'Secrets Store host call failed',
    SECRETS_STORE_PROTOCOL_ERROR   => 'Invalid Secrets Store protocol response or request',
    SECRETS_STORE_CAPABILITY_ERROR => 'Secrets Store capability is invalid or has expired',
    SECRETS_STORE_BINDING_ERROR    => 'Secrets Store binding is not available to this request',
    SECRETS_STORE_READ_ERROR       => 'Secrets Store retrieval failed',
);

sub new {
    my ($class, %opt)=@_;
    my $name=$opt{'name'};
    $name='SECRETS_STORE_ERROR'
        unless (defined($name)&&!ref($name)&&exists($message{$name}));
    my $self=bless({ name => $name, message => $message{$name} }, $class);
    return $self;
}


sub name { return shift()->{'name'}; }
sub message { return shift()->{'message'}; }


sub as_string {
    my ($self)=@_;
    return "$self->{'name'}: $self->{'message'}";
}

1;
