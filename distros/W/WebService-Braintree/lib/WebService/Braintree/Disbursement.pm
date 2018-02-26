package WebService::Braintree::Disbursement;
$WebService::Braintree::Disbursement::VERSION = '1.1';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::Disbursement

=head1 PURPOSE

This class represents a disbursement.

=cut

use WebService::Braintree::Transaction;

use Moose;
extends "WebService::Braintree::ResultObject";

=head1 CLASS METHODS

This class is B<NOT> an interface, so it does B<NOT> have any class methods.

=head1 OBJECT METHODS

=cut

sub BUILD {
    my ($self, $attributes) = @_;

    $self->merchant_account(WebService::Braintree::MerchantAccount->new($attributes->{merchant_account}));
    delete($attributes->{merchant_account});
    $self->set_attributes_from_hash($self, $attributes);
}

=pod

In addition to the methods provided by B<TODO>, this class provides the
following methods:

=head2 merchant_account()

This returns the merchant account associated with this notification (if any).
This will be an object of type L<WebService::Braintree::MerchantAccount/>.

=cut

has merchant_account => (is => 'rw');

=head2 transactions()

This returns the transactions associated with this disbursement. This is a
wrapper around L<WebService::Braintree::Transaction/search()>.

=cut

sub transactions {
    my $self = shift;
    WebService::Braintree::Transaction->search(sub {
        my $search = shift;
        $search->ids->in($self->transaction_ids);
    });
}

__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 TODO

=over 4

=item Need to document the keys and values that are returned

=item Need to document the required and optional input parameters

=item Need to document the possible errors/exceptions

=back

=cut
