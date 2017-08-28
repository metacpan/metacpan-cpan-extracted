package WebService::Braintree::Nonce;
$WebService::Braintree::Nonce::VERSION = '0.93';
use Moose;
extends 'WebService::Braintree::ResultObject';

has  billing_address => (is => 'rw');

sub BUILD {
    my ($self, $attributes) = @_;
    $self->set_attributes_from_hash($self, $attributes);
}


__PACKAGE__->meta->make_immutable;
1;
