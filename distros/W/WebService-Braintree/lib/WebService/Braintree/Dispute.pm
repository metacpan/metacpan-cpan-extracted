package WebService::Braintree::Dispute;
$WebService::Braintree::Dispute::VERSION = '0.91';
use WebService::Braintree::Dispute::TransactionDetails;
use WebService::Braintree::Dispute::Status;
use WebService::Braintree::Dispute::Reason;

use Moose;
extends 'WebService::Braintree::ResultObject';

has  transaction_details => (is => 'rw');

sub BUILD {
    my ($self, $attributes) = @_;

    $self->transaction_details(WebService::Braintree::Dispute::TransactionDetails->new($attributes->{transaction})) if ref($attributes->{transaction}) eq 'HASH';
    delete($attributes->{transaction});
    $self->set_attributes_from_hash($self, $attributes);
}

__PACKAGE__->meta->make_immutable;
1;
