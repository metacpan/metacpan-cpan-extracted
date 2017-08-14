package WebService::Braintree::MerchantAccount::AddressDetails;
$WebService::Braintree::MerchantAccount::AddressDetails::VERSION = '0.92';

use Moose;
extends "WebService::Braintree::ResultObject";

sub BUILD {
    my ($self, $attributes) = @_;
    $self->set_attributes_from_hash($self, $attributes);
}

__PACKAGE__->meta->make_immutable;
1;

