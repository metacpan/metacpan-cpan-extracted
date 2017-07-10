package WebService::Braintree::UnknownPaymentMethod;
$WebService::Braintree::UnknownPaymentMethod::VERSION = '0.91';
use Moose;
extends 'WebService::Braintree::PaymentMethod';

sub BUILD {
    my ($self, $attributes) = @_;
    $self->set_attributes_from_hash($self, $attributes);
}

__PACKAGE__->meta->make_immutable;
1;

