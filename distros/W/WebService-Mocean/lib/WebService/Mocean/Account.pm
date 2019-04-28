package WebService::Mocean::Account;

use Moo;
use Types::Standard qw(InstanceOf);

our $VERSION = '0.05';

has client => (
    is => 'rw',
    isa => InstanceOf['WebService::Mocean::Client'],
    required => 1,
);

sub get_balance {
    my ($self) = @_;

    return $self->client->request('account/balance', undef, 'get');
}

sub get_pricing {
    my ($self) = @_;

    return $self->client->request('account/pricing', undef, 'get');
}

1;
