package WebService::Braintree::MerchantAccount::IndividualDetails;
$WebService::Braintree::MerchantAccount::IndividualDetails::VERSION = '0.93';
use WebService::Braintree::MerchantAccount::AddressDetails;

use Moose;
extends "WebService::Braintree::ResultObject";

has  address_details => (is => 'rw');

sub BUILD {
    my ($self, $attributes) = @_;
    $self->address_details(WebService::Braintree::MerchantAccount::AddressDetails->new($attributes->{address})) if ref($attributes->{address}) eq 'HASH';
    delete($attributes->{address});
    $self->set_attributes_from_hash($self, $attributes);
}

__PACKAGE__->meta->make_immutable;
1;
