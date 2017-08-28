package WebService::Braintree::CreditCardVerification;
$WebService::Braintree::CreditCardVerification::VERSION = '0.93';
=head1 NAME

WebService::Braintree::CreditCardVerification

=head1 PURPOSE

This class searches, lists, and finds credit card verifications.

=cut

# TODO: Why are these used here?

use WebService::Braintree::CreditCard;
use WebService::Braintree::CreditCard::CardType;

use Moose;

=head1 CLASS METHODS

=head2 search()

This takes a subref which is used to set the search parameters and returns a
credit card verification object.

Please see L<Searching|WebService::Braintree/SEARCHING> for more information on
the subref and how it works.

=cut

sub search {
    my ($class, $block) = @_;
    $class->gateway->credit_card_verification->search($block);
}

=head2 all()

This returns all the credit card verifications.

=cut

sub all {
    my $class = shift;
    $class->gateway->credit_card_verification->all;
}

=head2 find()

This takes a token and returns the credit card verification associated with
that token.

=cut

sub find {
    my ($class, $token) = @_;
    $class->gateway->credit_card_verification->find($token);
}

sub gateway {
    WebService::Braintree->configuration->gateway;
}

=head1 OBJECT METHODS

UNKNOWN

=cut

has 'avs_error_response_code' => (is => 'ro');
has 'avs_postal_code_response_code' => (is => 'ro');
has 'avs_street_address_response_code' => (is => 'ro');
has 'cvv_response_code' => (is => 'ro');
has 'merchant_account_id' => (is => 'ro');
has 'processor_response_code' => (is => 'ro');
has 'processor_response_text' => (is => 'ro');
has 'id' => (is => 'ro');
has 'gateway_rejection_reason' => (is => 'ro');
has 'credit_card' => (is => 'ro'); # <-- Is this a ::CreditCard?
has 'billing' => (is => 'ro');
has 'created_at' => (is => 'ro');
has 'status' => (is => 'ro');

__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 TODO

=over 4

=item Need to document the keys and values that are returned

=item Need to document the required and optional input parameters

=item Need to document the possible errors/exceptions

=back

=cut
