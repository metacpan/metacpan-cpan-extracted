# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::_::Transaction::VisaCheckoutCardDetail;
$WebService::Braintree::_::Transaction::VisaCheckoutCardDetail::VERSION = '1.4';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::_::Transaction::VisaCheckoutCardDetail

=head1 PURPOSE

This class represents a transaction Visa checkout card detail.

This class will only be created as part of a L<response|WebService::Braintree::Result> or L<error response|WebService::Braintree::ErrorResult>.

=cut

use Moose;

extends 'WebService::Braintree::_';

=head1 ATTRIBUTES

=cut

=head2 bin()

This is the bin for this Visa checkout card detail.

=cut

has bin => (
    is => 'ro',
);

=head2 call_id()

This is the call ID for this Visa checkout card detail.

=cut

has call_id => (
    is => 'ro',
);

=head2 card_type()

This is the card type for this Visa checkout card detail.

=cut

has card_type => (
    is => 'ro',
);

=head2 cardholder_name()

This is the cardholder name for this Visa checkout card detail.

=cut

has cardholder_name => (
    is => 'ro',
);

=head2 commercial()

This is true if this Visa checkout card detail is commercial.

=cut

has commercial => (
    is => 'ro',
);

=head2 country_of_issuance()

This is the country of issuance for this Visa checkout card detail.

=cut

has country_of_issuance => (
    is => 'ro',
);

=head2 customer_location()

This is the customer location for this Visa checkout card detail.

=cut

has customer_location => (
    is => 'ro',
);

=head2 debit()

This is true if this Visa checkout card detail is debit.

=cut

has debit => (
    is => 'ro',
);

=head2 durbin_regulated()

This is true if this Visa checkout card detail is Durbin-regulated.

=cut

has durbin_regulated => (
    is => 'ro',
);

=head2 expiration_month()

This is the expiration month for this Visa checkout card detail.

=cut

has expiration_month => (
    is => 'ro',
);

=head2 expiration_year()

This is the expiration year for this Visa checkout card detail.

=cut

has expiration_year => (
    is => 'ro',
);

=head2 healthcare()

This is true if this Visa checkout card detail is healthcare.

=cut

has healthcare => (
    is => 'ro',
);

=head2 image_url()

This is the image URL for this Visa checkout card detail.

=cut

has image_url => (
    is => 'ro',
);

=head2 issuing_bank()

This is the issuing bank for this Visa checkout card detail.

=cut

has issuing_bank => (
    is => 'ro',
);

=head2 last_4()

This is the last-4 for this Visa checkout card detail.

=cut

has last_4 => (
    is => 'ro',
);

=head2 payroll()

This is true if this Visa checkout card detail is payroll.

=cut

has payroll => (
    is => 'ro',
);

=head2 prepaid()

This is true if this Visa checkout card detail is prepaid.

=cut

has prepaid => (
    is => 'ro',
);

=head2 product_id()

This is the product ID for this Visa checkout card detail.

=cut

has product_id => (
    is => 'ro',
);

=head2 token()

This is the token for this Visa checkout card detail.

=cut

has token => (
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

=head2 masked_number()

This returns the card number with the center masked out.

=cut

sub masked_number {
    my $self = shift;
    $self->bin . '******' . $self->last_4;
}

__PACKAGE__->meta->make_immutable;

1;
__END__
