use strict;
use warnings;

use WWW::Shopify;

package WWW::Shopify::Model::ShopifyPayment::Dispute;
use parent "WWW::Shopify::Model::Item";

my $fields; sub fields { return $fields; } 
BEGIN { $fields = {
	"id" => new WWW::Shopify::Field::Identifier(),
	"order_id" => new WWW::Shopify::Field::Relation::ReferenceOne('WWW::Shopify::Model::Order'),
	"type" => new WWW::Shopify::Field::String::Enum([qw(inquiry chargeback)]),
	"currency" => new WWW::Shopify::Field::Currency(),
	"amount" => new WWW::Shopify::Field::Money(),
	"reason" => new WWW::Shopify::Field::String::Enum([qw(bank_not_process credit_not_processed customer_initiated debit_not_authorized duplicate fraudulent general incorrect_account_details insufficient_funds product_not_received product_unacceptable subscription_cancelled unrecognized)]),
	"network_reason_code" => new WWW::Shopify::Field::Int(),
	"status" => new WWW::Shopify::Field::String::Enum([qw(needs_response under_review charge_refunded accepted won lost)]),
	"evidence_due_by" => new WWW::Shopify::Field::Date(),
	"evidence_sent_on" => new WWW::Shopify::Field::Date(),
	"finalized_on" => new WWW::Shopify::Field::Date(),
	"initiated_at" => new WWW::Shopify::Field::Date()
}; }

sub creatable { undef; }
sub updatable { undef; }
sub read_scope { "read_shopify_payments_disputes"; }
sub write_scope { undef; }


my $queries; sub queries { return $queries; }
BEGIN { $queries = {
	since_id => new WWW::Shopify::Query::LowerBound('id'),
	last_id => new WWW::Shopify::Query::UpperBound('id'),
	status => new WWW::Shopify::Query::Match('status'),
	initiated_at => new WWW::Shopify::Query::Match('initiated_at')
}; }

eval(__PACKAGE__->generate_accessors); die $@ if $@;

sub prefix { '/shopify_payments/'; }

1
