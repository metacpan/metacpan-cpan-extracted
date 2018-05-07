# vim: sw=4 ts=4 ft=perl

package # hide from pause
    WebService::Braintree::PayPalAccountGateway;

use 5.010_001;
use strictures 1;

use Moose;
extends 'WebService::Braintree::PaymentMethodGatewayBase';

use Carp qw(confess);

use WebService::Braintree::Util qw(validate_id);
use WebService::Braintree::Validations qw(verify_params);

use WebService::Braintree::_::PayPalAccount;

sub find {
    my ($self, $token) = @_;
    confess "NotFoundError" if !validate_id($token);
    $self->_find(paypal_account => (
        "/payment_methods/paypal_account/$token", 'get', undef,
    ));
}

sub create {
    my ($self, $token, $params) = @_;

    confess "NotFoundError" if !validate_id($token);
    confess "ArgumentError" unless verify_params($params, {
        billing_agreement_id => 1,
        customer_id => 1,
        email => 1,
        options => {
            fail_on_duplicate_payment_method => 1,
            make_default => 1,
        },
        token => 1,
    });

    $self->_create(
        "/payment_methods", 'post', { paypal_account => $params },
    );
}

sub update {
    my ($self, $token, $params) = @_;

    confess "NotFoundError" if !validate_id($token);
    confess "ArgumentError" unless verify_params($params, {
        billing_agreement_id => 1,
        email => 1,
        options => {
            fail_on_duplicate_payment_method => 1,
            make_default => 1,
        },
        token => 1,
    });

    $self->_update(
        "/payment_methods/paypal_account/$token", 'put', {
            paypal_account => $params,
        },
    );
}

sub delete {
    my ($self, $token) = @_;
    confess "NotFoundError" if !validate_id($token);
    $self->_make_request(
        "/payment_methods/paypal_account/$token", 'delete', undef,
    );
}

__PACKAGE__->meta->make_immutable;

1;
__END__
