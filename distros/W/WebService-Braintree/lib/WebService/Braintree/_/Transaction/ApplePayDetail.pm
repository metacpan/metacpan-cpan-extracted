# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::_::Transaction::ApplePayDetail;
$WebService::Braintree::_::Transaction::ApplePayDetail::VERSION = '1.3';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::_::Transaction::ApplePayDetail

=head1 PURPOSE

This class represents a transaction ApplePay detail.

This class will only be created as part of a L<response|WebService::Braintree::Result> or L<error response|WebService::Braintree::ErrorResult>.

=cut

use Moose;

extends 'WebService::Braintree::_';

=head1 ATTRIBUTES

=cut

=head2 card_type()

This is the card type for this transaction ApplePay detail.

=cut

has card_type => (
    is => 'ro',
);

=head2 cardholder_name()

This is the cardholder name for this transaction ApplePay detail.

=cut

has cardholder_name => (
    is => 'ro',
);

=head2 expiration_month()

This is the expiration month for this transaction ApplePay detail.

=cut

has expiration_month => (
    is => 'ro',
);

=head2 expiration_year()

This is the expiration year for this transaction ApplePay detail.

=cut

has expiration_year => (
    is => 'ro',
);

=head2 last_4()

This is the last_4 for this transaction ApplePay detail.

=cut

has last_4 => (
    is => 'ro',
);

=head2 payment_instrument_name()

This is the payment instrument name for this transaction ApplePay detail.

=cut

has payment_instrument_name => (
    is => 'ro',
);

=head2 source_description()

This is the source description for this transaction ApplePay detail.

=cut

has source_description => (
    is => 'ro',
);

=head1 METHODS

=head2 expiration_date()

This returns the expiration date in MM/YYYY format.

=cut

sub expiration_date {
    my $self = shift;
    $self->expiration_month . '/' . $self->expiration_year;
}

__PACKAGE__->meta->make_immutable;

1;
__END__
