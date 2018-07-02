# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::_::Transaction::PayPalDetail;
$WebService::Braintree::_::Transaction::PayPalDetail::VERSION = '1.6';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::_::Transaction::PayPalDetail

=head1 PURPOSE

This class represents a transaction PayPal detail.

This class will only be created as part of a L<response|WebService::Braintree::Result> or L<error response|WebService::Braintree::ErrorResult>.

=cut

use Moo;

extends 'WebService::Braintree::_';

=head1 ATTRIBUTES

=cut

=head2 authorization_id()

This is the authorization ID for this PayPal detail.

=cut

has authorization_id => (
    is => 'ro',
);

=head2 capture_id()

This is the capture ID for this PayPal detail.

=cut

has capture_id => (
    is => 'ro',
);

=head2 custom_field()

This is the custom field for this PayPal detail.

=cut

has custom_field => (
    is => 'ro',
);

=head2 debug_id()

This is the debug ID for this PayPal detail.

=cut

has debug_id => (
    is => 'ro',
);

=head2 description()

This is the description for this PayPal detail.

=cut

has description => (
    is => 'ro',
);

=head2 image_url()

This is the image URL for this PayPal detail.

=cut

has image_url => (
    is => 'ro',
);

=head2 payee_email()

This is the payee email for this PayPal detail.

=cut

has payee_email => (
    is => 'ro',
);

=head2 payer_email()

This is the payer_email for this PayPal detail.

=cut

has payer_email => (
    is => 'ro',
);

=head2 payer_first_name()

This is the payer's first name for this PayPal detail.

=cut

has payer_first_name => (
    is => 'ro',
);

=head2 payer_id()

This is the payer ID for this PayPal detail.

=cut

has payer_id => (
    is => 'ro',
);

=head2 payer_last_name()

This is the payer's last name for this PayPal detail.

=cut

has payer_last_name => (
    is => 'ro',
);

=head2 payer_status()

This is the payer's status for this PayPal detail.

=cut

has payer_status => (
    is => 'ro',
);

=head2 payment_id()

This is the payment ID for this PayPal detail.

=cut

has payment_id => (
    is => 'ro',
);

=head2 refund_id()

This is the refund ID for this PayPal detail.

=cut

has refund_id => (
    is => 'ro',
);

=head2 seller_protection_status()

This is the seller's protection status for this PayPal detail.

=cut

has seller_protection_status => (
    is => 'ro',
);

=head2 token()

This is the token for this PayPal detail.

=cut

has token => (
    is => 'ro',
);

=head2 transaction_fee_amount()

This is the transaction's fee amount for this PayPal detail.

=cut

has transaction_fee_amount => (
    is => 'ro',
);

=head2 transaction_fee_currency_iso_code()

This is the transaction's fee currency's ISO code for this PayPal detail.

=cut

has transaction_fee_currency_iso_code => (
    is => 'ro',
);

__PACKAGE__->meta->make_immutable;

1;
__END__
