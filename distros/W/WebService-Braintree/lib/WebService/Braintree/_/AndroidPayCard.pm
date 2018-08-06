# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::_::AndroidPayCard;
$WebService::Braintree::_::AndroidPayCard::VERSION = '1.7';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::_::AndroidPayCard

=head1 PURPOSE

This class represents a AndroidPay card.

This class will only be created as part of a L<response|WebService::Braintree::Result> or L<error response|WebService::Braintree::ErrorResult>.

=cut

use Moo;
use MooX::Aliases;

extends 'WebService::Braintree::_';

use Types::Standard qw(ArrayRef);
use WebService::Braintree::Types qw(
    Subscription
);

=head1 ATTRIBUTES

=cut

=head2 bin()

This returns the card's bin.

=cut

has bin => (
    is => 'ro',
);

=head2 created_at()

This returns when this card was created.

=cut

has created_at => (
    is => 'ro',
);

=head2 customer_id()

This returns the card's customer ID.

=cut

has customer_id => (
    is => 'ro',
);

=head2 default()

This returns if this card is default.

C<< is_default() >> is an alias for this attribute.

=cut

has default => (
    is => 'ro',
    alias => 'is_default',
);

=head2 expiration_month()

This returns the card's expiration month.

=cut

has expiration_month => (
    is => 'ro',
);

=head2 expiration_year()

This returns the card's expiration year.

=cut

has expiration_year => (
    is => 'ro',
);

=head2 google_transaction_id()

This returns the card's Google transaction ID.

=cut

has google_transaction_id => (
    is => 'ro',
);

=head2 image_url()

This returns the card's image URL.

=cut

has image_url => (
    is => 'ro',
);

=head2 source_card_type()

This returns the card's source card's type.

=cut

has source_card_type => (
    is => 'ro',
);

=head2 source_card_last4()

This returns the card's source card's last-4.

=cut

has source_card_last4 => (
    is => 'ro',
);

=head2 source_description()

This returns the card's source description.

=cut

has source_description => (
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

This returns the card's token.

=cut

has token => (
    is => 'ro',
);

=head2 updated_at()

This returns when this card was last updated.

=cut

has updated_at => (
    is => 'ro',
);

=head2 virtual_card_type()

This returns the card's virtual card's type.

=cut

has virtual_card_type => (
    is => 'ro',
);

=head2 virtual_card_last4()

This returns the card's virtual card's last-4.

=cut

has virtual_card_last4 => (
    is => 'ro',
);

=head1 METHODS

=head2 expiration_date()

This returns this card's expiration date in MM/YYYY format.

=cut

sub expiration_date {
    my $self = shift;
    return $self->expiration_month . "/" . $self->expiration_year;
}

__PACKAGE__->meta->make_immutable;

1;
__END__
