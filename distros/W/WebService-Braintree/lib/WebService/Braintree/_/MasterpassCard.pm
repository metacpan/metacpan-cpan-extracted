# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::_::MasterpassCard;
$WebService::Braintree::_::MasterpassCard::VERSION = '1.7';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::_::MasterpassCard

=head1 PURPOSE

This class represents a Masterpass card.

This class will only be created as part of a L<response|WebService::Braintree::Result> or L<error response|WebService::Braintree::ErrorResult>.

=cut

use Moo;
use MooX::Aliases;

extends 'WebService::Braintree::_';

use Types::Standard qw(ArrayRef);
use WebService::Braintree::Types qw(
    Address
    CreditCardVerification
    Subscription
);

=head1 ATTRIBUTES

=cut

=head2 billing_address()

This returns the card's billing address. This will be an object of type
L<address|WebService::Braintree::_::Address/>.

=cut

has billing_address => (
    is => 'ro',
    isa => Address,
    coerce => 1,
);

=head2 bin()

This is the bin for this card.

=cut

has bin => (
    is => 'ro',
);

=head2 card_type()

This is the type for this card.

=cut

has card_type => (
    is => 'ro',
);

=head2 cardholder_name()

This is the cardholder name for this card.

=cut

has cardholder_name => (
    is => 'ro',
);

=head2 commercial()

This is true if this card is commerical.

=cut

has commercial => (
    is => 'ro',
);

=head2 country_of_issuance()

This is true if this card is country-of-issuance.

=cut

has country_of_issuance => (
    is => 'ro',
);

=head2 created_at()

This returns when this card was created.

=cut

has created_at => (
    is => 'ro',
);

=head2 customer_id()

This is the customer ID for this card.

=cut

has customer_id => (
    is => 'ro',
);

=head2 customer_location()

This is the customer location for this card.

=cut

has customer_location => (
    is => 'ro',
);

=head2 debit()

This is true if this card is debit.

=cut

has debit => (
    is => 'ro',
);

=head2 default()

This is true if this card is default.

C<< is_default() >> is an alias for this attribute.

=cut

has default => (
    is => 'ro',
    alias => 'is_default',
);

=head2 durbin_regulated()

This is true if this card is Durbin-regulated.

=cut

has durbin_regulated => (
    is => 'ro',
);

=head2 expiration_month()

This is the expiration month for this card.

=cut

has expiration_month => (
    is => 'ro',
);

=head2 expiration_year()

This is the expiration year for this card.

=cut

has expiration_year => (
    is => 'ro',
);

=head2 expired()

This is true if this card is expired.

C<< is_expired() >> is an alias for this attribute.

=cut

has expired => (
    is => 'ro',
    alias => 'is_expired',
);

=head2 healthcare()

This is true if this card is healthcare.

=cut

has healthcare => (
    is => 'ro',
);

=head2 image_url()

This is the image URL for this card.

=cut

has image_url => (
    is => 'ro',
);

=head2 issuing_bank()

This is the issuing bank for this card.

=cut

has issuing_bank => (
    is => 'ro',
);

=head2 last_4()

This is the last-4 for this card.

=cut

has last_4 => (
    is => 'ro',
);

=head2 payroll()

This is true if this card is payroll.

=cut

has payroll => (
    is => 'ro',
);

=head2 prepaid()

This is true if this card is prepaid.

=cut

has prepaid => (
    is => 'ro',
);

=head2 product_id()

This is the product ID for this card.

=cut

has product_id => (
    is => 'ro',
);

=head2 subscriptions()

This returns the card's subscriptions. This will be an arrayref of
L<subscriptions|WebService::Braintree::_::Subscription/>.

=cut

has subscriptions => (
    is => 'ro',
    isa => ArrayRef[Subscription],
    coerce => 1,
);

=head2 token()

This is the token for this card.

=cut

has token => (
    is => 'ro',
);

=head2 unique_number_identifier()

This is the unique number identifier for this card.

=cut

has unique_number_identifier => (
    is => 'ro',
);

=head2 updated_at()

This returns when this card was last updated.

=cut

has updated_at => (
    is => 'ro',
);

=head2 verifications()

This returns the card's credit card verifications. This will be an arrayref of
L<credit card verifications|WebService::Braintree::_::CreditCardVerification/>.

=cut

has verifications => (
    is => 'ro',
    isa => ArrayRef[CreditCardVerification],
    coerce => 1,
);

=head1 METHODS

=head2 expiration_date()

This returns the expiration date in MM/YYYY format.

=cut

sub expiration_date {
    my $self = shift;
    return join('/', $self->expiration_month, $self->expiration_year);
}

=head2 masked_number()

This returns the card number with the center masked out.

=cut

sub masked_number {
    my $self = shift;
    return join('******', $self->bin, $self->last_4);
}

=head2 verification()

This returns the most recent verification from the arrayref in L</verifications()>.

=cut

sub verification {
    my $self = shift;

    return (
        sort {
            $b->created_at cmp $a->created_at
        } @{$self->verifications // []}
    )[0];
}

__PACKAGE__->meta->make_immutable;

1;
__END__
