# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::_::CreditCard;
$WebService::Braintree::_::CreditCard::VERSION = '1.6';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::_::CreditCard

=head1 PURPOSE

This class represents a credit card.

This class will only be created as part of a L<response|WebService::Braintree::Result> or L<error response|WebService::Braintree::ErrorResult>.

=cut

use Moo;
use MooX::Aliases;

extends 'WebService::Braintree::_';

use Types::Standard qw(ArrayRef Undef);
use WebService::Braintree::Types qw(
    Address
    CreditCardVerification
    PaymentMethodNonce
    Subscription
);

=head1 ATTRIBUTES

=cut

=head2 billing_address()

This returns the credit card's billing address (if it exists). This will be an
object of type L<WebService::Braintree::_::Address/>.

=cut

has billing_address => (
    is => 'ro',
    isa => Address,
    coerce => 1,
);

=head2 bin()

This is the bin for this credit card.

=cut

has bin => (
    is => 'ro',
);

=head2 card_type()

This is the card_type for this credit card.

=cut

has card_type => (
    is => 'ro',
);

=head2 cardholder_name()

This is the cardholder name for this credit card.

=cut

has cardholder_name => (
    is => 'ro',
);

=head2 commercial()

This is true if this credit card is commercial.

=cut

has commercial => (
    is => 'ro',
);

=head2 country_of_issuance()

This is the country of issuance for this credit card.

=cut

has country_of_issuance => (
    is => 'ro',
);

=head2 created_at()

This is when this credit card was created.

=cut

# Coerce this to Datetime
has created_at => (
    is => 'ro',
);

=head2 customer_id()

This is the customer id for this credit card.

=cut

has customer_id => (
    is => 'ro',
);

=head2 customer_location()

This is the customer location for this credit card.

=cut

has customer_location => (
    is => 'ro',
);

=head2 debit()

This is true if this credit card is debit.

=cut

has debit => (
    is => 'ro',
);

=head2 default()

This is true if this credit card is debit.

C<< is_default() >> is an alias for this attribute.

=cut

has default => (
    is => 'ro',
    alias => 'is_default',
);

=head2 durbin_regulated()

This is true if this credit card is Durbin-regulated.

=cut

has durbin_regulated => (
    is => 'ro',
);

=head2 expiration_month()

This is the expiration month for this credit card.

=cut

has expiration_month => (
    is => 'ro',
);

=head2 expiration_year()

This is the expiration year for this credit card.

=cut

has expiration_year => (
    is => 'ro',
);

=head2 expired()

This is true if this credit card is expired.

C<< is_expired() >> is an alias for this attribute.

=cut

has expired => (
    is => 'ro',
    alias => 'is_expired',
);

=head2 healthcare()

This is true if this credit card is healthcare.

=cut

has healthcare => (
    is => 'ro',
);

=head2 image_url()

This is the image url for this credit card.

=cut

# Coerce this to URI
has image_url => (
    is => 'ro',
);

=head2 issuing_bank()

This is the issuing bank for this credit card.

=cut

has issuing_bank => (
    is => 'ro',
);

=head2 last_4()

This is the last 4 digits for this credit card.

=cut

has last_4 => (
    is => 'ro',
);

=head2 payment_method_nonce()

This is the payment method nonce for this credit card. If one is not returned,
then it will be created by default from the L</token>. If the token is undef,
then this will be undef as well.

C<< nonce() >> is an alias for this attribute.

=cut

has payment_method_nonce => (
    is => 'ro',
    isa => PaymentMethodNonce | Undef,
    coerce => 1,
    default => sub {
        my $self = shift;
        return unless $self->token;
        return WebService::Braintree::PaymentMethodNonce->create($self->token);
    },
    alias => 'nonce',
);

=head2 payroll()

This is true if this credit card is payroll.

=cut

has payroll => (
    is => 'ro',
);

=head2 prepaid()

This is true if this credit card is prepaid.

=cut

has prepaid => (
    is => 'ro',
);

=head2 product_id()

This is the product id for this credit card.

=cut

has product_id => (
    is => 'ro',
);

=head2 subscriptions()

This is an arrayref of L<subscriptions|WebService::Braintree::_::Susbcription>
associated with this credit card.

=cut

has subscriptions => (
    is => 'ro',
    isa => ArrayRef[Subscription],
    coerce => 1,
);

=head2 token()

This is the token for this credit card.

=cut

has token => (
    is => 'ro',
);

=head2 unique_number_identifier()

This is the unique number identifier for this credit card.

=cut

has unique_number_identifier => (
    is => 'ro',
);

=head2 updated_at()

This is when this credit card was last updated. If it has never been updated,
then this should equal the L</created_at> date.

=cut

# Coerce this to Datetime
has updated_at => (
    is => 'ro',
);

=head2 venmo_sdk()

This is true if this credit card is managed by the Venmo SDK.

C<< is_venmo_sdk() >> is an alias for this attribute.

=cut

has venmo_sdk => (
    is => 'ro',
    alias => 'is_venmo_sdk',
);

=head2 verifications()

This is an arrayref of L<verifications|WebService::Braintree::_::CreditCardVerification>
associated with this credit card.

=cut

has verifications => (
    is => 'ro',
    isa => ArrayRef[CreditCardVerification],
    coerce => 1,
);

=head1 METHODS

=head2 masked_number()

This returns a masked credit card number suitable for display.

=cut

sub masked_number {
    my $self = shift;
    return $self->bin . "******" . $self->last_4;
}

=head2 expiration_date()

This returns the credit card's expiration in MM/YYYY format.

=cut

sub expiration_date {
    my $self = shift;
    return $self->expiration_month . "/" . $self->expiration_year;
}

=head2 verification()

This returns the most recent L<verification|WebService::Braintree::_::CreditCardVerification> (if any) associated with this credit card.

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
