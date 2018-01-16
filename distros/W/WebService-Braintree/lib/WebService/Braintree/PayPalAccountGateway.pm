package WebService::Braintree::PayPalAccountGateway;
$WebService::Braintree::PayPalAccountGateway::VERSION = '1.0';
use 5.010_001;
use strictures 1;

use Moose;
with 'WebService::Braintree::Role::MakeRequest';

use Carp qw(confess);

has 'gateway' => (is => 'ro');

sub find {
    my ($self, $token) = @_;
    $self->_make_request(
        "/payment_methods/paypal_account/$token", "get", undef,
    )->paypal_account;
}

sub create {
    my ($self, $token, $params) = @_;
    $self->_make_request("/payment_methods", "post", {
        paypal_account => $params
    });
}

sub update {
    my ($self, $token, $params) = @_;
    $self->_make_request("/payment_methods/paypal_account/$token", "put", {
        paypal_account => $params
    });
}

sub delete {
    my ($self, $token) = @_;
    $self->_make_request(
        "/payment_methods/paypal_account/$token", "delete", undef,
    );
}

__PACKAGE__->meta->make_immutable;

1;
__END__
