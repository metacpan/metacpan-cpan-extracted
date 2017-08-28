package WebService::Braintree::MerchantAccount::FundingDetails;
$WebService::Braintree::MerchantAccount::FundingDetails::VERSION = '0.93';

use Moose;
extends "WebService::Braintree::ResultObject";

sub BUILD {
    my ($self, $attributes) = @_;
    $self->set_attributes_from_hash($self, $attributes);
}

__PACKAGE__->meta->make_immutable;
1;

