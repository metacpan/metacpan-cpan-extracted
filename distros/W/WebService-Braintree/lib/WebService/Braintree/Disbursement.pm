package WebService::Braintree::Disbursement;
$WebService::Braintree::Disbursement::VERSION = '0.91';

use Moose;
extends "WebService::Braintree::ResultObject";

has  merchant_account => (is => 'rw');

sub BUILD {
    my ($self, $attributes) = @_;

    $self->merchant_account(WebService::Braintree::MerchantAccount->new($attributes->{merchant_account}));
    delete($attributes->{merchant_account});
    $self->set_attributes_from_hash($self, $attributes);
}

sub transactions {
    my $self = shift;
    WebService::Braintree::Transaction->search(sub {
                                                   my $search = shift;
                                                   $search->ids->in($self->transaction_ids);
                                               });
}


__PACKAGE__->meta->make_immutable;
1;
