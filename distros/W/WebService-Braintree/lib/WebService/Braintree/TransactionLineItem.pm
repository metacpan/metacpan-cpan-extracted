# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::TransactionLineItem;
$WebService::Braintree::TransactionLineItem::VERSION = '1.5';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::TransactionLineItem

=head1 PURPOSE

This class finds transaction line items.

=cut

use Moose;

with 'WebService::Braintree::Role::Interface';

=head1 CLASS METHODS

=head2 find_all($transaction_id)

This takes a transaction id and returns an arrayref of the transaction's line-items.

=cut

sub find_all {
    my ($self, $txn_id) = @_;
    return $self->gateway->transaction_line_item->find_all($txn_id);
}

__PACKAGE__->meta->make_immutable;

1;
__END__
