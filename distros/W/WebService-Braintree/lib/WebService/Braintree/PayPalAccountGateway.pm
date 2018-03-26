# vim: sw=4 ts=4 ft=perl

package # hide from pause
    WebService::Braintree::PayPalAccountGateway;

use 5.010_001;
use strictures 1;

use Moose;
extends 'WebService::Braintree::PaymentMethodGatewayBase';

use Carp qw(confess);

use WebService::Braintree::_::PayPalAccount;

sub find {
    my ($self, $token) = @_;
    $self->_find(paypal_account => (
        "/payment_methods/paypal_account/$token", 'get', undef,
    ));
}

sub create {
    my ($self, $token, $params) = @_;
    $self->_create(
        "/payment_methods", 'post', { paypal_account => $params },
    );
}

sub update {
    my ($self, $token, $params) = @_;
    $self->_update(
        "/payment_methods/paypal_account/$token", 'put', {
            paypal_account => $params,
        },
    );
}

sub delete {
    my ($self, $token) = @_;
    $self->_make_request(
        "/payment_methods/paypal_account/$token", 'delete', undef,
    );
}

__PACKAGE__->meta->make_immutable;

1;
__END__
