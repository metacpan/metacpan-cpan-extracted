# vim: sw=4 ts=4 ft=perl

package # hide from pause
    WebService::Braintree::CreditCardGateway;

use 5.010_001;
use strictures 1;

use Moose;
extends 'WebService::Braintree::PaymentMethodGatewayBase';
with 'WebService::Braintree::Role::CollectionBuilder';

use Carp qw(confess);
use Scalar::Util qw(blessed);
use Try::Tiny;

use WebService::Braintree::Util qw(validate_id);
use WebService::Braintree::Validations qw(verify_params credit_card_signature);

use WebService::Braintree::_::CreditCard;

sub create {
    my ($self, $params) = @_;
    confess "ArgumentError" unless verify_params($params, credit_card_signature);
    return $self->_create(
        "/payment_methods", 'post', {credit_card => $params},
    );
}

sub delete {
    my ($self, $token) = @_;
    confess "NotFoundError" unless validate_id($token);
    $self->_make_request("/payment_methods/credit_card/$token", "delete", undef);
}

sub update {
    my ($self, $token, $params) = @_;
    confess "ArgumentError" unless verify_params($params, credit_card_signature);
    return $self->_update(
        "/payment_methods/credit_card/$token", "put", {credit_card => $params},
    );
}

sub find {
    my ($self, $token) = @_;
    confess "NotFoundError" unless validate_id($token);
    return $self->_find(credit_card => (
        "/payment_methods/credit_card/${token}", 'get', undef,
    ));
}

sub from_nonce {
    my ($self, $nonce) = @_;
    confess "NotFoundError" unless validate_id($nonce);

    try {
        return $self->_make_request("/payment_methods/from_nonce/$nonce", "get", undef)->credit_card;
    } catch {
        confess "Payment method with nonce $nonce locked, consumed or not found";
    }
}

sub expired {
    my ($self) = @_;

    return $self->resource_collection({
        ids_url => "/payment_methods/all/expired_ids",
        obj_url => "/payment_methods/all/expired",
        inflate => [qw/payment_methods credit_card _::CreditCard/],
    });
}

sub expiring_between {
    my ($self, $start, $end) = @_;
    confess "ArgumentError" unless $start && blessed($start) && $start->isa('DateTime');
    confess "ArgumentError" unless $end && blessed($end) && $end->isa('DateTime');

    $start = $start->strftime('%m%Y');
    $end   = $end->strftime('%m%Y');
    my $params = "start=${start}&end=${end}";

    return $self->resource_collection({
        ids_url => "/payment_methods/all/expiring_ids?${params}",
        obj_url => "/payment_methods/all/expiring?${params}",
        inflate => [qw/payment_methods credit_card _::CreditCard/],
    });
}

__PACKAGE__->meta->make_immutable;

1;
__END__
