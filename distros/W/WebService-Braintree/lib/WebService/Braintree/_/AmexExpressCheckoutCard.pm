# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::_::AmexExpressCheckoutCard;
$WebService::Braintree::_::AmexExpressCheckoutCard::VERSION = '1.4';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::_::AmexExpressCheckoutCard

=head1 PURPOSE

This class represents a AMEX Express Checkout card.

This class will only be created as part of a L<response|WebService::Braintree::Result> or L<error response|WebService::Braintree::ErrorResult>.

=cut

use Moose;
use MooseX::Aliases;

extends 'WebService::Braintree::_';

use WebService::Braintree::_::Subscription;

=head1 ATTRIBUTES

=cut

=head2 bin()

This returns the card's bin.

=cut

has bin => (
    is => 'ro',
);

=head2 card_member_number()

This returns the card's card-member number.

=cut

has card_member_number => (
    is => 'ro',
);

=head2 card_type()

This returns the card's type.

=cut

has card_type => (
    is => 'ro',
);

=head2 created_at()

This returns when this card was created.

=cut

has created_at => (
    is => 'ro',
);

=head2 customer_id()

This returns the card's customer's ID.

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

=head2 image_url()

This returns the card's image URL.

=cut

has image_url => (
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
    isa => 'ArrayRefOfSubscription',
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
