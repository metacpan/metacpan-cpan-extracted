# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::_::PaymentMethodNonceDetails;
$WebService::Braintree::_::PaymentMethodNonceDetails::VERSION = '1.5';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::_::PaymentMethodNonceDetails

=head1 PURPOSE

This class represents a payment method nonce's details.

This class will only be created as part of a L<response|WebService::Braintree::Result> or L<error response|WebService::Braintree::ErrorResult>.

=cut

use Moose;

extends 'WebService::Braintree::_';

=head1 ATTRIBUTES

=cut

=head2 card_type()

This is the card type for this payment method nonce.

=cut

has card_type => (
    is => 'ro',
);

=head2 last_four()

This is the last-four of this payment method nonce.

=cut

has last_four => (
    is => 'ro',
);

=head2 last_two()

This is the last-two of this payment method nonce.

=cut

has last_two => (
    is => 'ro',
);

__PACKAGE__->meta->make_immutable;

1;
__END__
