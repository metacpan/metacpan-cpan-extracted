package WebService::Braintree::MerchantAccount::BusinessDetails;
$WebService::Braintree::MerchantAccount::BusinessDetails::VERSION = '1.0';
use 5.010_001;
use strictures 1;

use WebService::Braintree::MerchantAccount::AddressDetails;

use Moose;
extends "WebService::Braintree::ResultObject";

has  address_details => (is => 'rw');

sub BUILD {
    my ($self, $attrs) = @_;

    $self->build_sub_object($attrs,
        method => 'address_details',
        class  => 'MerchantAccount::AddressDetails',
        key    => 'address',
    );

    $self->set_attributes_from_hash($self, $attrs);
}

__PACKAGE__->meta->make_immutable;

1;
__END__
