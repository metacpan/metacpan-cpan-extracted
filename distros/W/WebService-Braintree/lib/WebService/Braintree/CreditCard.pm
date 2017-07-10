package WebService::Braintree::CreditCard;
$WebService::Braintree::CreditCard::VERSION = '0.91';
use WebService::Braintree::CreditCard::CardType;
use WebService::Braintree::CreditCard::Location;
use WebService::Braintree::CreditCard::Prepaid;
use WebService::Braintree::CreditCard::Debit;
use WebService::Braintree::CreditCard::Payroll;
use WebService::Braintree::CreditCard::Healthcare;
use WebService::Braintree::CreditCard::DurbinRegulated;
use WebService::Braintree::CreditCard::Commercial;
use WebService::Braintree::CreditCard::CountryOfIssuance;
use WebService::Braintree::CreditCard::IssuingBank;

use Moose;
extends 'WebService::Braintree::PaymentMethod';

has  billing_address => (is => 'rw');

sub BUILD {
    my ($self, $attributes) = @_;
    $self->billing_address(WebService::Braintree::Address->new($attributes->{billing_address})) if ref($attributes->{billing_address}) eq 'HASH';
    delete($attributes->{billing_address});
    $self->set_attributes_from_hash($self, $attributes);
}

sub create {
    my ($class, $params) = @_;
    $class->gateway->credit_card->create($params);
}

sub delete {
    my ($class, $token) = @_;
    $class->gateway->credit_card->delete($token);
}

sub update {
    my($class, $token, $params) = @_;
    $class->gateway->credit_card->update($token, $params);
}

sub find {
    my ($class, $token) = @_;
    $class->gateway->credit_card->find($token);
}

sub from_nonce {
    my ($class, $nonce) = @_;
    $class->gateway->credit_card->from_nonce($nonce);
}

sub gateway {
    WebService::Braintree->configuration->gateway;
}

sub masked_number {
    my $self = shift;
    return $self->bin . "******" . $self->last_4;
}

sub expiration_date {
    my $self = shift;
    return $self->expiration_month . "/" . $self->expiration_year;
}

sub is_default {
    return shift->default;
}

sub is_venmo_sdk {
    my $self = shift;
    return $self->venmo_sdk;
}

__PACKAGE__->meta->make_immutable;
1;
