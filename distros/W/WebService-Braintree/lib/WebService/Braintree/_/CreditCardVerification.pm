# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::_::CreditCardVerification;
$WebService::Braintree::_::CreditCardVerification::VERSION = '1.2';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::_::CreditCardVerification

=head1 PURPOSE

This class represents a credit card verification.

This class will only be created as part of a L<response|WebService::Braintree::Result> or L<error response|WebService::Braintree::ErrorResult>.

=cut

use Moose;
use MooseX::Aliases;

extends 'WebService::Braintree::_';

=head1 ATTRIBUTES

=cut

=head2 amount()

This is the amount for this credit card verification.

=cut

# Ruby coerces this to "big_decimal"
has amount => (
    is => 'ro',
);

=head2 avs_error_response_code()

This is the avs error response code for this credit card verification.

=cut

has avs_error_response_code => (
    is => 'ro',
);

=head2 avs_postal_code_response_code()

This is the avs postal code response code for this credit card verification.

=cut

has avs_postal_code_response_code => (
    is => 'ro',
);

=head2 avs_street_address_response_code()

This is the avs street address respons code for this credit card verification.

=cut

has avs_street_address_response_code => (
    is => 'ro',
);

=head2 billing()

This returns the credit card verification's billing address (if it exists). This will be an
object of type L<WebService::Braintree::_::Address/>.

C<< billing_address() >> is an alias to this attribute.

=cut

has billing => (
    is => 'ro',
    isa => 'WebService::Braintree::_::Address',
    coerce => 1,
    alias => 'billing_address',
);

=head2 created_at()

This is when this credit card was created.

=cut

# Coerce this to Datetime
has created_at => (
    is => 'ro',
);

=head2 credit_card()

This returns the credit card verification's credit card (if it exists). This will be an
object of type L<WebService::Braintree::_::CreditCard/>.

=cut

has credit_card => (
    is => 'ro',
    isa => 'WebService::Braintree::_::CreditCard',
    coerce => 1,
);

=head2 currency_iso_code()

This is the currency ISO code for this credit card verification.

=cut

has currency_iso_code => (
    is => 'ro',
);

=head2 cvv_response_code()

This is the CVV response code for this credit card verification.

=cut

has cvv_response_code => (
    is => 'ro',
);

=head2 gateway_rejection_reason()

This is the gateway rejection reason for this credit card verification.

=cut

has gateway_rejection_reason => (
    is => 'ro',
);

=head2 id()

This is the id for this credit card verification.

=cut

has id => (
    is => 'ro',
);

=head2 merchant_account_id()

This is the merchant account id for this credit card verification.

=cut

has merchant_account_id => (
    is => 'ro',
);

=head2 processor_response_code()

This is the processor response code for this credit card verification.

=cut

has processor_response_code => (
    is => 'ro',
);

=head2 processor_response_text()

This is the processor response text for this credit card verification.

=cut

has processor_response_text => (
    is => 'ro',
);

=head2 risk_data()

This is the risk data for this credit card verification.

=cut

has risk_data => (
    is => 'ro',
);

=head2 status()

This is the status for this credit card verification.

=cut

has status => (
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

__PACKAGE__->meta->make_immutable;

1;
__END__
