#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify;

package WWW::Shopify::Model::Dispute;
use parent "WWW::Shopify::Model::Item";

my $fields; sub fields { return $fields; } 
BEGIN { $fields = {
	"id" => new WWW::Shopify::Field::Identifier(),
	"order_id" => new WWW::Shopify::Field::Relation::ReferenceOne('WWW::Shopify::Model::Order'),
	"type" => new WWW::Shopify::Field::String::Enum([qw(inquiry chargeback)]),
	"amount" => new WWW::Shopify::Field::Money(),
	"currency" => new WWW::Shopify::Field::Currency(),
	"reason" => new WWW::Shopify::Field::String::Enum([qw(bank_not_process credit_not_processed customer_initiated debit_not_authorized duplicate fraudulent general incorrect_account_details insufficient_funds product_not_received product_unacceptable subscription_canceled unrecognized)]),
	"network_reason_code" => new WWW::Shopify::Field::BigInt(),
	"status" => new WWW::Shopify::Field::String::Enum([qw(needs_response under_review charge_refunded accepted won lost)]),
	"evidence_due_by" => new WWW::Shopify::Field::Date(),
	"evidence_sent_on" => new WWW::Shopify::Field::Date(),
	"finalized_on" => new WWW::Shopify::Field::Date()
}; }
my $queries; sub queries { return $queries; }
BEGIN { $queries = {
	since_id => new WWW::Shopify::Query::LowerBound('id'),
	last_id => new WWW::Shopify::Query::UpperBound('id'),
	status => new WWW::Shopify::Query::Enum('status', [qw(needs_response under_review charge_refunded accepted won lost)]),
	#initiated_at => new WWW::Shopify::Query::Match('date')
}; }

sub updatable { undef };
sub creatable { undef };

sub read_scope { return "read_shopify_payments_disputes"; }

eval(__PACKAGE__->generate_accessors); die $@ if $@;

1
