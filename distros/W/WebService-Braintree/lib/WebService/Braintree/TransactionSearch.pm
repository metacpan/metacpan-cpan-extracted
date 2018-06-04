# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::TransactionSearch;
$WebService::Braintree::TransactionSearch::VERSION = '1.5';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::TransactionSearch

=head1 PURPOSE

This class represents a search for transactions.

This class should never be instantiated directly. Instead, you will access
objects of this class through the search interface.

=cut

use Moose;
extends 'WebService::Braintree::AdvancedSearch';

use WebService::Braintree::Transaction::Status;

=head1 FIELDS

=cut

my $field = WebService::Braintree::AdvancedSearchFields->new(metaclass => __PACKAGE__->meta);

=head2 amount

This is a L<range field|WebService::Braintree::AdvancedSearchNodes/"Range Field">. It will restrict the search to subscriptions created between the two values.

=cut

$field->range("amount");

=head2 authorization_expired_at

This is a L<range field|WebService::Braintree::AdvancedSearchNodes/"Range Field">. It will restrict the search to subscriptions created between the two values.

=cut

$field->range("authorization_expired_at");

=head2 authorized_at

This is a L<range field|WebService::Braintree::AdvancedSearchNodes/"Range Field">. It will restrict the search to subscriptions created between the two values.

=cut

$field->range("authorized_at");

=head2 billing_company

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to transactions matching a specific billing company.

=cut

$field->text("billing_company");

=head2 billing_country_name

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to transactions matching a specific billing country name.

=cut

$field->text("billing_country_name");

=head2 billing_extended_address

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to transactions matching a specific billing extended address.

=cut

$field->text("billing_extended_address");

=head2 billing_first_name

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to transactions matching a specific billing first name.

=cut

$field->text("billing_first_name");

=head2 billing_last_name

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to transactions matching a specific billing last name.

=cut

$field->text("billing_last_name");

=head2 billing_locality

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to transactions matching a specific billing locality.

=cut

$field->text("billing_locality");

=head2 billing_postal_code

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to transactions matching a specific billing postal code.

=cut

$field->text("billing_postal_code");

=head2 billing_region

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to transactions matching a specific billing region.

=cut

$field->text("billing_region");

=head2 billing_street_address

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to transactions matching a specific billing street address.

=cut

$field->text("billing_street_address");

=head2 created_at

This is a L<range field|WebService::Braintree::AdvancedSearchNodes/"Range Field">. It will restrict the search to subscriptions created between the two values.

=cut

$field->range("created_at");

=head2 created_using

This is a L<multiple-values field|WebService::Braintree::AdvancedSearchNodes/"Multiple Values Field">. It will restrict the search to a list of specific values regarding how this transaction was created.

This list is restricted to the values defined by L<WebService::Braintree::Transaction::CreatedUsing/All>

=cut

$field->multiple_values("created_using", WebService::Braintree::Transaction::CreatedUsing->All);

=head2 credit_card_cardholder_name

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to transactions matching a specific credit card cardholder name.

=cut

$field->text("credit_card_cardholder_name");

=head2 credit_card_customer_location

This is a L<multiple-values field|WebService::Braintree::AdvancedSearchNodes/"Multiple Values Field">. It will restrict the search to a list of specific location types.

This list is restricted to the values defined by L<WebService::Braintree::CreditCard::Location/All>

=cut

$field->multiple_values("credit_card_customer_location", WebService::Braintree::CreditCard::Location->All);

=head2 credit_card_expiration_date

This is an L<equality field|WebService::Braintree::AdvancedSearchNodes/"Equality Field">. It will restrict the search to transactions with
credit cards with a specific expiration date.

=cut

$field->equality("credit_card_expiration_date");

=head2 credit_card_number

This is a L<partial-match field|WebService::Braintree::AdvancedSearchNodes/"Partial Match Field">. It will restrict the search to transactions with
credit cards containing a specific card number.

=cut

$field->partial_match("credit_card_number");

=head2 credit_card_card_type

This is a L<multiple-values field|WebService::Braintree::AdvancedSearchNodes/"Multiple Values Field">. It will restrict the search to a list of specific credit card card-types.

This list is restricted to the values defined by L<WebService::Braintree::CreditCard::CardType/All>

=cut

$field->multiple_values("credit_card_card_type", WebService::Braintree::CreditCard::CardType->All);

=head2 currency

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to transactions matching a specific currency.

=cut

$field->text("currency");

=head2 customer_company

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to transactions matching a specific customer company.

=cut

$field->text("customer_company");

=head2 customer_email

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to transactions matching a specific customer email.

=cut

$field->text("customer_email");

=head2 customer_fax

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to transactions matching a specific customer fax.

=cut

$field->text("customer_fax");

=head2 customer_first_name

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to transactions matching a specific customer first name.

=cut

$field->text("customer_first_name");

=head2 customer_id

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to transactions matching a specific customer ID.

=cut

$field->text("customer_id");

=head2 customer_last_name

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to transactions matching a specific customer last name.

=cut

$field->text("customer_last_name");

=head2 customer_phone

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to transactions matching a specific customer phone number.

=cut

$field->text("customer_phone");

=head2 customer_website

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to transactions matching a specific customer website.

=cut

$field->text("customer_website");

=head2 failed_at

This is a L<range field|WebService::Braintree::AdvancedSearchNodes/"Range Field">. It will restrict the search to subscriptions created between the two values.

=cut

$field->range("failed_at");

=head2 gateway_rejected_at

This is a L<range field|WebService::Braintree::AdvancedSearchNodes/"Range Field">. It will restrict the search to subscriptions created between the two values.

=cut

$field->range("gateway_rejected_at");

=head2 id

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to transactions matching a specific ID.

=cut

$field->text("id");

=head2 ids

This is a L<multiple-values field|WebService::Braintree::AdvancedSearchNodes/"Multiple Values Field">. It will restrict the search to a list of specific ids.

=cut

$field->multiple_values("ids");

=head2 merchant_account_id

This is a L<multiple-values field|WebService::Braintree::AdvancedSearchNodes/"Multiple Values Field">. It will restrict the search to a list of specific merchant account IDs.

=cut

$field->multiple_values("merchant_account_id");

=head2 order_id

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to transactions matching a specific order ID.

=cut

$field->text("order_id");

=head2 payment_method_token

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to transactions matching a specific payment method token.

=cut

$field->text("payment_method_token");

=head2 paypal_payment_id

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to transactions matching a specific PayPal payment ID.

=cut

$field->text("paypal_payment_id");

=head2 paypal_authorization_id

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to transactions matching a specific PayPal authorization ID.

=cut

$field->text("paypal_authorization_id");

=head2 paypal_payer_email

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to transactions matching a specific PayPal payer email.

=cut

$field->text("paypal_payer_email");

=head2 processor_authorization_code

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to transactions matching a specific processor authorization code.

=cut

$field->text("processor_authorization_code");

=head2 processor_declined_at

This is a L<range field|WebService::Braintree::AdvancedSearchNodes/"Range Field">. It will restrict the search to subscriptions created between the two values.

=cut

$field->range("processor_declined_at");

=head2 refund

This is a L<key-value field|WebService::Braintree::AdvancedSearchNodes/"Key Value Field">. It will restrict the search to transactions that match the specified value.

=cut

$field->key_value("refund");

=head2 settled_at

This is a L<range field|WebService::Braintree::AdvancedSearchNodes/"Range Field">. It will restrict the search to subscriptions created between the two values.

=cut

$field->range("settled_at");

=head2 settlement_batch_id

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to transactions matching a specific settlement batch ID.

=cut

$field->text("settlement_batch_id");

=head2 shipping_company

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to transactions matching a specific shipping company.

=cut

$field->text("shipping_company");

=head2 shipping_country_name

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to transactions matching a specific shipping address country name.

=cut

$field->text("shipping_country_name");

=head2 shipping_extended_address

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to transactions matching a specific shipping address extended address.

=cut

$field->text("shipping_extended_address");

=head2 shipping_first_name

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to transactions matching a specific shipping address first name.

=cut

$field->text("shipping_first_name");

=head2 shipping_last_name

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to transactions matching a specific shipping address last name.

=cut

$field->text("shipping_last_name");

=head2 shipping_locality

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to transactions matching a specific shipping address locality.

=cut

$field->text("shipping_locality");

=head2 shipping_postal_code

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to transactions matching a specific shipping address postal code.

=cut

$field->text("shipping_postal_code");

=head2 shipping_region

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to transactions matching a specific shipping address region.

=cut

$field->text("shipping_region");

=head2 shipping_street_address

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to transactions matching a specific shipping address street address.

=cut

$field->text("shipping_street_address");

=head2 source

This is a L<multiple-values field|WebService::Braintree::AdvancedSearchNodes/"Multiple Values Field">. It will restrict the search to a list of specific transaction sources.

This list is restricted to the values defined by L<WebService::Braintree::Transaction::Source/All>

=cut

$field->multiple_values("source", WebService::Braintree::Transaction::Source->All);

=head2 status

This is a L<multiple-values field|WebService::Braintree::AdvancedSearchNodes/"Multiple Values Field">. It will restrict the search to a list of specific transaction statuses.

This list is restricted to the values defined by L<WebService::Braintree::Transaction::Status/All>

=cut

$field->multiple_values("status", WebService::Braintree::Transaction::Status->All);

=head2 submitted_for_settlement_at

This is a L<range field|WebService::Braintree::AdvancedSearchNodes/"Range Field">. It will restrict the search to subscriptions created between the two values.

=cut

$field->range("submitted_for_settlement_at");

=head2 ids

This is a L<multiple-values field|WebService::Braintree::AdvancedSearchNodes/"Multiple Values Field">. It will restrict the search to a list of specific transaction types.

This list is restricted to the values defined by L<WebService::Braintree::Transaction::Type/All>

=cut

$field->multiple_values("type", WebService::Braintree::Transaction::Type->All);

=head2 voided_at

This is a L<range field|WebService::Braintree::AdvancedSearchNodes/"Range Field">. It will restrict the search to subscriptions created between the two values.

=cut

$field->range("voided_at");

__PACKAGE__->meta->make_immutable;

1;
__END__
