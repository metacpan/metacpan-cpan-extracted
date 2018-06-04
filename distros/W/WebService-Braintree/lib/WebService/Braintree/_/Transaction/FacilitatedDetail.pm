# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::_::Transaction::FacilitatedDetail;
$WebService::Braintree::_::Transaction::FacilitatedDetail::VERSION = '1.5';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::_::Transaction::FacilitatedDetail

=head1 PURPOSE

This class represents a facilitated detail of a transaction.

This class will only be created as part of a L<response|WebService::Braintree::Result> or L<error response|WebService::Braintree::ErrorResult>.

=cut

use Moose;

extends 'WebService::Braintree::_';

=head1 ATTRIBUTES

=cut

=head2 merchant_id()

This is the merchant ID of this facilitated detail.

=cut

has merchant_id => (
    is => 'ro',
);

=head2 merchant_name()

This is the merchant name of this facilitated detail.

=cut

has merchant_name => (
    is => 'ro',
);

=head2 payment_method_nonce()

This is the payment method nonce of this facilitated detail.

=cut

has payment_method_nonce => (
    is => 'ro',
);

__PACKAGE__->meta->make_immutable;

1;
__END__
