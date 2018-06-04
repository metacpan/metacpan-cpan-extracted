# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::_::Transaction::IdealPaymentDetail;
$WebService::Braintree::_::Transaction::IdealPaymentDetail::VERSION = '1.5';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::_::Transaction::IdealPaymentDetail

=head1 PURPOSE

This class represents a ideal payment detail of a transaction.

This class will only be created as part of a L<response|WebService::Braintree::Result> or L<error response|WebService::Braintree::ErrorResult>.

=cut

use Moose;

extends 'WebService::Braintree::_';

=head1 ATTRIBUTES

=cut

=head2 bic()

This is the bic for this ideal payment detail.

=cut

has bic => (
    is => 'ro',
);

=head2 ideal_payment_id()

This is the ideal payment ID for this ideal payment detail.

=cut

has ideal_payment_id => (
    is => 'ro',
);

=head2 ideal_transaction_id()

This is the ideal transaction ID for this ideal payment detail.

=cut

has ideal_transaction_id => (
    is => 'ro',
);

=head2 image_url()

This is the image URL for this ideal payment detail.

=cut

has image_url => (
    is => 'ro',
);

=head2 masked_iban()

This is the masked IBAN for this ideal payment detail.

=cut

has masked_iban => (
    is => 'ro',
);

__PACKAGE__->meta->make_immutable;

1;
__END__
