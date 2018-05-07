# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::_::Dispute::Transaction;
$WebService::Braintree::_::Dispute::Transaction::VERSION = '1.3';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::_::Dispute::Transaction

=head1 PURPOSE

This class represents a transaction of a dispute.

This class will only be created as part of a L<response|WebService::Braintree::Result> or L<error response|WebService::Braintree::ErrorResult>.

=cut

use Moose;

extends 'WebService::Braintree::_';

=head1 ATTRIBUTES

=cut

=head2 amount()

This is the amount for this dispute's transaction.

=cut

# Coerce this to "big_decimal"
has amount => (
    is => 'ro',
);

=head2 created_at()

This is when this dispute's transaction was created.

=cut

# Coerce this to DateTime
has created_at => (
    is => 'ro',
);

=head2 id()

This is the ID for this dispute's transaction.

=cut

has id => (
    is => 'ro',
);

=head2 order_id()

This is the order ID for this dispute's transaction.

=cut

has order_id => (
    is => 'ro',
);

=head2 purchase_order_number()

This is the purchase order number for this dispute's transaction.

=cut

has purchase_order_number => (
    is => 'ro',
);

=head2 payment_instrument_subtype()

This is the payment instrument subtype for this dispute's transaction.

=cut

has payment_instrument_subtype => (
    is => 'ro',
);

__PACKAGE__->meta->make_immutable;

1;
__END__
