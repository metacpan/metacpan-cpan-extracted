package WebService::Braintree::PayPalAccountGateway;
$WebService::Braintree::PayPalAccountGateway::VERSION = '0.9';
use Moose;
with 'WebService::Braintree::Role::MakeRequest';

use Carp qw(confess);

has 'gateway' => (is => 'ro');

sub find {
    my ($self, $token) = @_;
    $self->_make_request("/payment_methods/paypal_account/$token", "get", undef)->paypal_account;
}

sub update {
    my ($self, $token, $params) = @_;
    $self->_make_request(
        "/payment_methods/paypal_account/$token",
        "put",
        {
            paypal_account => $params
        });
}

__PACKAGE__->meta->make_immutable;
1;

