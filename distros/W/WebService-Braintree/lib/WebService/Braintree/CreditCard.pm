package WebService::Braintree::CreditCard;
$WebService::Braintree::CreditCard::VERSION = '0.92';
use WebService::Braintree::CreditCard::CardType;
use WebService::Braintree::CreditCard::Location;
use WebService::Braintree::CreditCard::Prepaid;
use WebService::Braintree::CreditCard::Debit;
use WebService::Braintree::CreditCard::Payroll;
use WebService::Braintree::CreditCard::Healthcare;
use WebService::Braintree::CreditCard::DurbinRegulated;
use WebService::Braintree::CreditCard::Commercial;
use WebService::Braintree::CreditCard::CountryOfIssuance;
use WebService::Braintree::CreditCard::IssuingBank;

=head1 NAME

WebService::Braintree::CreditCard

=head1 PURPOSE

This class creates, updates, deletes, and finds credit cards.

=cut

use Moose;
extends 'WebService::Braintree::PaymentMethod';

=head1 CLASS METHODS

=head2 create()

This takes a hashref of parameters and returns the credit card created.

=cut

sub create {
    my ($class, $params) = @_;
    $class->gateway->credit_card->create($params);
}

=head2 create()

This takes a nonce and returns the credit card (if it exists).

=cut

sub from_nonce {
    my ($class, $nonce) = @_;
    $class->gateway->credit_card->from_nonce($nonce);
}

=head2 find()

This takes a token and returns the credit card (if it exists).

=cut

sub find {
    my ($class, $token) = @_;
    $class->gateway->credit_card->find($token);
}

=head2 update()

This takes a token and a hashref of parameters. It will update the
corresponding credit card (if found) and returns the updated credit card.

=cut

sub update {
    my($class, $token, $params) = @_;
    $class->gateway->credit_card->update($token, $params);
}

=head2 update()

This takes a token. It will delete the corresponding credit card (if found).

=cut

sub delete {
    my ($class, $token) = @_;
    $class->gateway->credit_card->delete($token);
}

sub gateway {
    WebService::Braintree->configuration->gateway;
}

=head1 OBJECT METHODS

In addition to the methods provided by the keys returned from Braintree, this
class provides the following methods:

=head2 billing_address()

This returns the credit card's billing address (if it exists). This will be an
object of type L<WebService::Braintree::Address/>.

=cut

has billing_address => (is => 'rw');

sub BUILD {
    my ($self, $attributes) = @_;
    $self->billing_address(WebService::Braintree::Address->new($attributes->{billing_address})) if ref($attributes->{billing_address}) eq 'HASH';
    delete($attributes->{billing_address});
    $self->set_attributes_from_hash($self, $attributes);
}

=head2 masked_number()

This returns a masked credit card number suitable for display.

=cut

sub masked_number {
    my $self = shift;
    return $self->bin . "******" . $self->last_4;
}

=head2 expiration_date()

This returns the credit card's expiration in MM/YY format.

=cut

sub expiration_date {
    my $self = shift;
    return $self->expiration_month . "/" . $self->expiration_year;
}

=head2 is_default()

This returns true if this credit card is the default credit card.

=cut

sub is_default {
    return shift->default;
}

=head2 is_venmo_sdk()

This returns true if this credit card uses the Venmo SDK.

=cut

sub is_venmo_sdk {
    my $self = shift;
    return $self->venmo_sdk;
}

__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 NOTES

Most of the classes normally used in WebService::Braintree inherit from
L<WebService::Braintree::ResultObject/>. This class, however, inherits from
L<WebService::Braintree::PaymentMethod/>. The primary benefit of this is that
these objects have a C<< token() >> attribute.

=head1 TODO

=over 4

=item Need to document the keys and values that are returned

=item Need to document the required and optional input parameters

=item Need to document the possible errors/exceptions

=back

=cut
