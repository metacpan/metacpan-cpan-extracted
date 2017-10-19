package WebService::Braintree::UnknownPaymentMethod;
$WebService::Braintree::UnknownPaymentMethod::VERSION = '0.94';
use 5.010_001;
use strictures 1;

use Moose;
extends 'WebService::Braintree::PaymentMethod';

sub BUILD {
    my ($self, $attributes) = @_;
    $self->set_attributes_from_hash($self, $attributes);
}

__PACKAGE__->meta->make_immutable;

1;
__END__
