# vim: sw=4 ts=4 ft=perl

package # hide from pause
    WebService::Braintree::PaymentMethodGateway;

use 5.010_001;
use strictures 1;

use Moose;
extends 'WebService::Braintree::PaymentMethodGatewayBase';

use Carp qw(confess);

use WebService::Braintree::Util qw(
    hash_to_query_string
    validate_id
);
use WebService::Braintree::Validations qw(verify_params address_signature);

use WebService::Braintree::PaymentMethodResult;

sub create {
    my ($self, $params) = @_;
    confess "ArgumentError" unless verify_params($params, _signature_for('create'));
    return $self->_create(
        "/payment_methods", 'post', {payment_method => $params},
    );
}

sub update {
    my ($self, $token, $params) = @_;
    confess "ArgumentError" unless verify_params($params, _signature_for('update'));
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
    my ($self, $token, $params) = @_;
    confess "NotFoundError" unless validate_id($token);
    my $query = '';
    if ($params) {
        confess "ArgumentError" unless verify_params($params, {
            revoke_all_grants => 1,
        });
        $query = '?' . hash_to_query_string($params);
    }
    $self->_make_request("/payment_methods/any/${token}${query}", 'delete');
}

sub grant {
    my ($self, $token, $params) = @_;

    confess "NotFoundError" unless validate_id($token);
    #confess "ArgumentError" unless verify_params($params, {
    #    revoke_all_grants => 1,
    #});

    $self->_make_request("/payment_methods/grant", 'post', {payment_method => { %$params, shared_payment_method_token => $token}});
}

sub revoke {
    my ($self, $token) = @_;
    confess "NotFoundError" unless validate_id($token);
    $self->_make_request("/payment_methods/revoke", 'post', {payment_method => { shared_payment_method_token => $token}});
}

sub _signature_for {
    my ($type) = @_;

    my $signature = {
        billing_address => address_signature(),
        billing_address_id => 1,
        cardholder_name => 1,
        cvv => 1,
        device_session_id => 1,
        expiration_date => 1,
        expiration_month => 1,
        expiration_year => 1,
        number => 1,
        token => 1,
        venmo_sdk_payment_method_code => 1,
        device_data => 1,
        fraud_merchant_id => 1,
        payment_method_nonce => 1,
        options => {
            make_default => 1,
            verification_merchant_account_id => 1,
            verify_card => 1,
            venmo_sdk_session => 1,
            verification_amount => 1,
            paypal => {
                payee_email => 1,
                order_id => 1,
                custom_field => 1,
                description => 1,
                amount => 1,
                shipping => address_signature(),
            },
        },
    };

    if ($type eq 'create') {
        $signature = {
            %{$signature},
            customer_id => 1,
            paypal_refresh_token => 1,
            paypal_vault_without_upgrade => 1,
        };
        $signature->{options}{fail_on_duplicate_payment_method} = 1;
    }
    elsif ($type eq 'update') {
        $signature->{billing_address}{update_existing} = 1;
    }

    return $signature;
}

__PACKAGE__->meta->make_immutable;

1;
__END__
