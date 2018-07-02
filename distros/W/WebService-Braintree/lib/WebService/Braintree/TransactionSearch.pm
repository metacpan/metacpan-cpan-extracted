# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::TransactionSearch;
$WebService::Braintree::TransactionSearch::VERSION = '1.6';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::TransactionSearch

=head1 PURPOSE

This class represents a search for transactions.

This class should never be instantiated directly. Instead, you will access
objects of this class through the search interface.

=cut

use Moo;
with 'WebService::Braintree::Role::AdvancedSearch';

use constant FIELDS => [];

use WebService::Braintree::Transaction::Status;

=head1 FIELDS

=cut

=head2 amount

This is a L<range field|WebService::Braintree::AdvancedSearchNodes/"Range Field">. It will restrict the search to subscriptions created between the two values.

=cut

__PACKAGE__->range_field("amount");

=head2 authorization_expired_at

This is a L<range field|WebService::Braintree::AdvancedSearchNodes/"Range Field">. It will restrict the search to subscriptions created between the two values.

=cut

__PACKAGE__->range_field("authorization_expired_at");

=head2 authorized_at

This is a L<range field|WebService::Braintree::AdvancedSearchNodes/"Range Field">. It will restrict the search to subscriptions created between the two values.

=cut

__PACKAGE__->range_field("authorized_at");

=head2 billing_company

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to transactions matching a specific billing company.

=cut

__PACKAGE__->text_field("billing_company");

=head2 billing_country_name

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to transactions matching a specific billing country name.

=cut

__PACKAGE__->text_field("billing_country_name");

=head2 billing_extended_address

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to transactions matching a specific billing extended address.

=cut

__PACKAGE__->text_field("billing_extended_address");

=head2 billing_first_name

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to transactions matching a specific billing first name.

=cut

__PACKAGE__->text_field("billing_first_name");

=head2 billing_last_name

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to transactions matching a specific billing last name.

=cut

__PACKAGE__->text_field("billing_last_name");

=head2 billing_locality

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to transactions matching a specific billing locality.

=cut

__PACKAGE__->text_field("billing_locality");

=head2 billing_postal_code

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to transactions matching a specific billing postal code.

=cut

__PACKAGE__->text_field("billing_postal_code");

=head2 billing_region

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to transactions matching a specific billing region.

=cut

__PACKAGE__->text_field("billing_region");

=head2 billing_street_address

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to transactions matching a specific billing street address.

=cut

__PACKAGE__->text_field("billing_street_address");

=head2 created_at

This is a L<range field|WebService::Braintree::AdvancedSearchNodes/"Range Field">. It will restrict the search to subscriptions created between the two values.

=cut

__PACKAGE__->range_field("created_at");

=head2 created_using

This is a L<multiple-values field|WebService::Braintree::AdvancedSearchNodes/"Multiple Values Field">. It will restrict the search to a list of specific values regarding how this transaction was created.

This list is restricted to the values defined by L<WebService::Braintree::Transaction::CreatedUsing/All>

=cut

__PACKAGE__->multiple_values_field("created_using", WebService::Braintree::Transaction::CreatedUsing->All);

=head2 credit_card_cardholder_name

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to transactions matching a specific credit card cardholder name.

=cut

__PACKAGE__->text_field("credit_card_cardholder_name");

=head2 credit_card_customer_location

This is a L<multiple-values field|WebService::Braintree::AdvancedSearchNodes/"Multiple Values Field">. It will restrict the search to a list of specific location types.

This list is restricted to the values defined by L<WebService::Braintree::CreditCard::Location/All>

=cut

__PACKAGE__->multiple_values_field("credit_card_customer_location", WebService::Braintree::CreditCard::Location->All);

=head2 credit_card_expiration_date

This is an L<equality field|WebService::Braintree::AdvancedSearchNodes/"Equality Field">. It will restrict the search to transactions with
credit cards with a specific expiration date.

=cut

__PACKAGE__->equality_field("credit_card_expiration_date");

=head2 credit_card_number

This is a L<partial-match field|WebService::Braintree::AdvancedSearchNodes/"Partial Match Field">. It will restrict the search to transactions with
credit cards containing a specific card number.

=cut

__PACKAGE__->partial_match_field("credit_card_number");

=head2 credit_card_card_type

This is a L<multiple-values field|WebService::Braintree::AdvancedSearchNodes/"Multiple Values Field">. It will restrict the search to a list of specific credit card card-types.

This list is restricted to the values defined by L<WebService::Braintree::CreditCard::CardType/All>

=cut

__PACKAGE__->multiple_values_field("credit_card_card_type", WebService::Braintree::CreditCard::CardType->All);

=head2 currency

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to transactions matching a specific currency.

=cut

__PACKAGE__->text_field("currency");

=head2 customer_company

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to transactions matching a specific customer company.

=cut

__PACKAGE__->text_field("customer_company");

=head2 customer_email

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to transactions matching a specific customer email.

=cut

__PACKAGE__->text_field("customer_email");

=head2 customer_fax

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to transactions matching a specific customer fax.

=cut

__PACKAGE__->text_field("customer_fax");

=head2 customer_first_name

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to transactions matching a specific customer first name.

=cut

__PACKAGE__->text_field("customer_first_name");

=head2 customer_id

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to transactions matching a specific customer ID.

=cut

__PACKAGE__->text_field("customer_id");

=head2 customer_last_name

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to transactions matching a specific customer last name.

=cut

__PACKAGE__->text_field("customer_last_name");

=head2 customer_phone

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to transactions matching a specific customer phone number.

=cut

__PACKAGE__->text_field("customer_phone");

=head2 customer_website

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to transactions matching a specific customer website.

=cut

__PACKAGE__->text_field("customer_website");

=head2 failed_at

This is a L<range field|WebService::Braintree::AdvancedSearchNodes/"Range Field">. It will restrict the search to subscriptions created between the two values.

=cut

__PACKAGE__->range_field("failed_at");

=head2 gateway_rejected_at

This is a L<range field|WebService::Braintree::AdvancedSearchNodes/"Range Field">. It will restrict the search to subscriptions created between the two values.

=cut

__PACKAGE__->range_field("gateway_rejected_at");

=head2 id

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to transactions matching a specific ID.

=cut

__PACKAGE__->text_field("id");

=head2 ids

This is a L<multiple-values field|WebService::Braintree::AdvancedSearchNodes/"Multiple Values Field">. It will restrict the search to a list of specific ids.

=cut

__PACKAGE__->multiple_values_field("ids");

=head2 merchant_account_id

This is a L<multiple-values field|WebService::Braintree::AdvancedSearchNodes/"Multiple Values Field">. It will restrict the search to a list of specific merchant account IDs.

=cut

__PACKAGE__->multiple_values_field("merchant_account_id");

=head2 order_id

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to transactions matching a specific order ID.

=cut

__PACKAGE__->text_field("order_id");

=head2 payment_method_token

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to transactions matching a specific payment method token.

=cut

__PACKAGE__->text_field("payment_method_token");

=head2 paypal_payment_id

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to transactions matching a specific PayPal payment ID.

=cut

__PACKAGE__->text_field("paypal_payment_id");

=head2 paypal_authorization_id

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to transactions matching a specific PayPal authorization ID.

=cut

__PACKAGE__->text_field("paypal_authorization_id");

=head2 paypal_payer_email

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to transactions matching a specific PayPal payer email.

=cut

__PACKAGE__->text_field("paypal_payer_email");

=head2 processor_authorization_code

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to transactions matching a specific processor authorization code.

=cut

__PACKAGE__->text_field("processor_authorization_code");

=head2 processor_declined_at

This is a L<range field|WebService::Braintree::AdvancedSearchNodes/"Range Field">. It will restrict the search to subscriptions created between the two values.

=cut

__PACKAGE__->range_field("processor_declined_at");

=head2 refund

This is a L<key-value field|WebService::Braintree::AdvancedSearchNodes/"Key Value Field">. It will restrict the search to transactions that match the specified value.

=cut

__PACKAGE__->key_value_field("refund");

=head2 settled_at

This is a L<range field|WebService::Braintree::AdvancedSearchNodes/"Range Field">. It will restrict the search to subscriptions created between the two values.

=cut

__PACKAGE__->range_field("settled_at");

=head2 settlement_batch_id

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to transactions matching a specific settlement batch ID.

=cut

__PACKAGE__->text_field("settlement_batch_id");

=head2 shipping_company

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to transactions matching a specific shipping company.

=cut

__PACKAGE__->text_field("shipping_company");

=head2 shipping_country_name

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to transactions matching a specific shipping address country name.

=cut

__PACKAGE__->text_field("shipping_country_name");

=head2 shipping_extended_address

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to transactions matching a specific shipping address extended address.

=cut

__PACKAGE__->text_field("shipping_extended_address");

=head2 shipping_first_name

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to transactions matching a specific shipping address first name.

=cut

__PACKAGE__->text_field("shipping_first_name");

=head2 shipping_last_name

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to transactions matching a specific shipping address last name.

=cut

__PACKAGE__->text_field("shipping_last_name");

=head2 shipping_locality

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to transactions matching a specific shipping address locality.

=cut

__PACKAGE__->text_field("shipping_locality");

=head2 shipping_postal_code

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to transactions matching a specific shipping address postal code.

=cut

__PACKAGE__->text_field("shipping_postal_code");

=head2 shipping_region

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to transactions matching a specific shipping address region.

=cut

__PACKAGE__->text_field("shipping_region");

=head2 shipping_street_address

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to transactions matching a specific shipping address street address.

=cut

__PACKAGE__->text_field("shipping_street_address");

=head2 source

This is a L<multiple-values field|WebService::Braintree::AdvancedSearchNodes/"Multiple Values Field">. It will restrict the search to a list of specific transaction sources.

This list is restricted to the values defined by L<WebService::Braintree::Transaction::Source/All>

=cut

__PACKAGE__->multiple_values_field("source", WebService::Braintree::Transaction::Source->All);

=head2 status

This is a L<multiple-values field|WebService::Braintree::AdvancedSearchNodes/"Multiple Values Field">. It will restrict the search to a list of specific transaction statuses.

This list is restricted to the values defined by L<WebService::Braintree::Transaction::Status/All>

=cut

__PACKAGE__->multiple_values_field("status", WebService::Braintree::Transaction::Status->All);

=head2 submitted_for_settlement_at

This is a L<range field|WebService::Braintree::AdvancedSearchNodes/"Range Field">. It will restrict the search to subscriptions created between the two values.

=cut

__PACKAGE__->range_field("submitted_for_settlement_at");

=head2 ids

This is a L<multiple-values field|WebService::Braintree::AdvancedSearchNodes/"Multiple Values Field">. It will restrict the search to a list of specific transaction types.

This list is restricted to the values defined by L<WebService::Braintree::Transaction::Type/All>

=cut

__PACKAGE__->multiple_values_field("type", WebService::Braintree::Transaction::Type->All);

=head2 voided_at

This is a L<range field|WebService::Braintree::AdvancedSearchNodes/"Range Field">. It will restrict the search to subscriptions created between the two values.

=cut

__PACKAGE__->range_field("voided_at");

__PACKAGE__->meta->make_immutable;

1;
__END__
