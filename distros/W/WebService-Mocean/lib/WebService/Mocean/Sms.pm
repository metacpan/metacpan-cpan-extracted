package WebService::Mocean::Sms;

use utf8;
use strictures 2;
use namespace::clean;

use Moo;
use Types::Standard qw(InstanceOf);

our $VERSION = '0.05';

has client => (
    is => 'rw',
    isa => InstanceOf['WebService::Mocean::Client'],
    required => 1,
);

sub send {
    my ($self, $params) = @_;

    return $self->client->request('sms', $params, 'post');
}

sub send_verification_code {
    my ($self, $params) = @_;

    return $self->client->request('verify/req', $params, 'post');
}

sub check_verification_code {
    my ($self, $params) = @_;

    return $self->client->request('verify/check', $params, 'post');
}

1;
