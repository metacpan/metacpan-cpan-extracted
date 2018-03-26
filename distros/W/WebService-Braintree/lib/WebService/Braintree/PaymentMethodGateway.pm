# vim: sw=4 ts=4 ft=perl

package # hide from pause
    WebService::Braintree::PaymentMethodGateway;

use 5.010_001;
use strictures 1;

use Moose;
extends 'WebService::Braintree::PaymentMethodGatewayBase';

use Carp qw(confess);
use Scalar::Util qw(blessed);

use WebService::Braintree::Util qw(validate_id);

use WebService::Braintree::PaymentMethodResult;

sub create {
    my ($self, $params) = @_;
    return $self->_create(
        "/payment_methods", 'post', {payment_method => $params},
    );
}

sub update {
    my ($self, $token, $params) = @_;
    return $self->_update(
        "/payment_methods/any/" . $token, "put", {payment_method => $params},
    );
}

sub find {
    my ($self, $token) = @_;
    confess "NotFoundError" unless validate_id($token);
    return $self->_find(payment_method => (
        "/payment_methods/any/${token}", 'get', undef,
    ));
}

sub delete {
    my ($self, $token) = @_;
    $self->_make_request("/payment_methods/any/" . $token, 'delete');
}

sub grant {
    my ($self, $token, $params) = @_;
    $self->_make_request("/payment_methods/grant", 'post', {payment_method => { %$params, shared_payment_method_token => $token}});
}

sub revoke {
    my ($self, $token) = @_;
    $self->_make_request("/payment_methods/revoke", 'post', {payment_method => { shared_payment_method_token => $token}});
}

__PACKAGE__->meta->make_immutable;

1;
__END__
