package WebService::Braintree::PartnerMerchant;
$WebService::Braintree::PartnerMerchant::VERSION = '0.91';
use Moose;
extends 'WebService::Braintree::ResultObject';

sub BUILD {
    my ($self, $attributes) = @_;
    $self->set_attributes_from_hash($self, $attributes);
}

__PACKAGE__->meta->make_immutable;
1;

