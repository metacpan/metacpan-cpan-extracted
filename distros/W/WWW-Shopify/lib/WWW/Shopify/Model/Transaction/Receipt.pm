#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify;

package WWW::Shopify::Model::Transaction::Receipt;
use parent 'WWW::Shopify::Model::NestedItem';

my $fields; sub fields { return $fields; } 
BEGIN { $fields = {
	"testcase" => new WWW::Shopify::Field::Boolean(),
	"authorization" => new WWW::Shopify::Field::String::Regex("[0-9]{4,10}"),
	# Stripe?
	"code" => new WWW::Shopify::Field::String(),
	"success" => new WWW::Shopify::Field::String(),
	"message" => new WWW::Shopify::Field::String(),
	"front_end" => new WWW::Shopify::Field::Int(),
	"avs_end" => new WWW::Shopify::Field::String(),
	"avs_result" => new WWW::Shopify::Field::String(),
	"avs_result_code" => new WWW::Shopify::Field::String(),
	"card_code" => new WWW::Shopify::Field::String(),
	"authorization_code" => new WWW::Shopify::Field::String(),
	"cardholder_authorization_code" => new WWW::Shopify::Field::String(),
	"action" => new WWW::Shopify::Field::String(),
	"risk" => new WWW::Shopify::Field::String(),
	"reference" => new WWW::Shopify::Field::String(),
	"order_number" => new WWW::Shopify::Field::String(),
	"recurring" => new WWW::Shopify::Field::String(),
	# Paypal
	"ack" => new WWW::Shopify::Field::String::Enum(["Success", "Failure"]),
	"timestamp" => new WWW::Shopify::Field::Date(),
	"correlation_id" => new WWW::Shopify::Field::String(),
	"version" => new WWW::Shopify::Field::Int(),
	"build" => new WWW::Shopify::Field::Int(),
	"amount" => new WWW::Shopify::Field::Money(),
	"amount_currency" => new WWW::Shopify::Field::Currency(),
	"avs_code" => new WWW::Shopify::Field::String(),
	"cvv2_code" => new WWW::Shopify::Field::String(),
	"transaction_id" => new WWW::Shopify::Field::String(),
	"payment_details" => new WWW::Shopify::Field::Freeform(),
	"response_code" => new WWW::Shopify::Field::String(),
	"response_reason_code" =>  new WWW::Shopify::Field::String(),
	"transaction_type" => new WWW::Shopify::Field::String(),
	"payment_type" => new WWW::Shopify::Field::String(),
	"payment_date" => new WWW::Shopify::Field::Date(),
	"gross_amount" => new WWW::Shopify::Field::Money(),
	"gross_amount_currency_id" => new WWW::Shopify::Field::Currency(),
	"fee_amount" => new WWW::Shopify::Field::Money(),
	"fee_amount_currency_id" => new WWW::Shopify::Field::Currency(),
	"tax_amount" => new WWW::Shopify::Field::Money(),
	"tax_amount_currency_id" => new WWW::Shopify::Field::Currency(),
	"exchange_rate" => new WWW::Shopify::Field::String(),
	"payment_status" => new WWW::Shopify::Field::String(),
	"pending_reason" => new WWW::Shopify::Field::String(),
	"reason_code" => new WWW::Shopify::Field::String(),
	"protection_eligibility" => new WWW::Shopify::Field::String(),
	"protection_eligibility_type" => new WWW::Shopify::Field::String(),
	"secure_merchant_account_id" => new WWW::Shopify::Field::String(),
	"success_page_redirect_requested" => new WWW::Shopify::Field::Boolean(),
	"Token" => new WWW::Shopify::Field::String(),
	"PaymentInfo" => new WWW::Shopify::Field::Freeform(),
	# Shopify payments.
	"object" => new WWW::Shopify::Field::String(),
	"created" => new WWW::Shopify::Field::Int(),
	"livemode" => new WWW::Shopify::Field::Boolean(),
	"paid" => new WWW::Shopify::Field::Boolean(),
	"currency" => new WWW::Shopify::Field::String(),
	"refunded" => new WWW::Shopify::Field::Freeform(),
	"card" => new WWW::Shopify::Field::Freeform(),
	"captured" => new WWW::Shopify::Field::Boolean(),
	"refunds" => new WWW::Shopify::Field::Freeform(),
	"balance_transaction" => new WWW::Shopify::Field::Freeform(),
	"failure_message" => new WWW::Shopify::Field::Freeform(),
	"failure_code" => new WWW::Shopify::Field::Freeform(),
	"amount_refunded" => new WWW::Shopify::Field::Int(),
	"customer" => new WWW::Shopify::Field::Freeform(),
	"invoice" => new WWW::Shopify::Field::Freeform(),
	"description" => new WWW::Shopify::Field::String(),
	"dispute" => new WWW::Shopify::Field::Freeform(),
	"metadata" => new WWW::Shopify::Field::Freeform(),
	"statement_description" => new WWW::Shopify::Field::Freeform(),
	"fraud_details" => new WWW::Shopify::Field::Freeform(),
	"receipt_email" => new WWW::Shopify::Field::Freeform(),
	"receipt_number" => new WWW::Shopify::Field::Freeform(),
	"shipping" => new WWW::Shopify::Field::Freeform(),
	"source" => new WWW::Shopify::Field::Freeform(),
	# Gift Card
	"gift_card_id" => new WWW::Shopify::Field::String(),
	"gift_card_masked_code" => new WWW::Shopify::Field::String(),
	"gift_card_last_characters" => new WWW::Shopify::Field::String()
}; }

eval(__PACKAGE__->generate_accessors); die $@ if $@;

1;
