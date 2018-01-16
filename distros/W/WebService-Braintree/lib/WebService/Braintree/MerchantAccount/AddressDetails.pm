package WebService::Braintree::MerchantAccount::AddressDetails;
$WebService::Braintree::MerchantAccount::AddressDetails::VERSION = '1.0';
use 5.010_001;
use strictures 1;

use Moose;
extends "WebService::Braintree::ResultObject";

sub BUILD {
    my ($self, $attributes) = @_;
    $self->set_attributes_from_hash($self, $attributes);
}

__PACKAGE__->meta->make_immutable;

1;
__END__
