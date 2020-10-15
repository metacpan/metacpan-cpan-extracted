use strict;
use warnings;

use WWW::Shopify;

package WWW::Shopify::Model::ShopifyPayment::Balance::Transaction;
use parent "WWW::Shopify::Model::Item";

my $fields; sub fields { return $fields; } 
BEGIN { $fields = {
	"id" => new WWW::Shopify::Field::Identifier(),
	"type" => new WWW::Shopify::Field::String::Enum([qw(charge refund dispute reserve adjustment credit debit payout payout_failure payout_cancellation)]),
	"test" => new WWW::Shopify::Field::Boolean(),
	"payout_id" => new WWW::Shopify::Field::Relation::Parent(),
	"payout_status" => new WWW::Shopify::Field::String::Enum([qw(pending scheduled paid)]),
	"currency" => new WWW::Shopify::Field::Currency(),
	"amount" => new WWW::Shopify::Field::Money(),
	"fee" => new WWW::Shopify::Field::Money(),
	"net" => new WWW::Shopify::Field::Money(),
	"source_id" => new WWW::Shopify::Field::BigInt(),
	"source_type" => new WWW::Shopify::Field::String::Enum([qw(charge refund dispute reserve adjustment payout)]),
	"source_order_transaction_id" => new WWW::Shopify::Field::Relation::ReferenceOne("WWW::Shopify::Model::Transaction"),
	"source_order_id" => new WWW::Shopify::Field::Relation::ReferenceOne("WWW::Shopify::Model::Order"),
	"processed_at" => new WWW::Shopify::Field::Date(),
}; }

my $queries; sub queries { return $queries; }
BEGIN { $queries = {
	test => new WWW::Shopify::Query::Match('test'),
	payout_id => new WWW::Shopify::Query::Match('payout_id'),
	payout_status => new WWW::Shopify::Query::Match('payout_status'),
	last_id => new WWW::Shopify::Query::UpperBound('id'),
	since_id => new WWW::Shopify::Query::LowerBound('id')
}; }

sub parent { 'WWW::Shopify::Model::ShopifyPayment::Payout' }


sub get_all_through_parent { undef; }
sub get_through_parent { undef; }
sub creatable { undef; }
sub updatable { undef; }
sub read_scope { "read_shopify_payments_payouts"; }
sub write_scope { undef; }
sub prefix { '/shopify_payments/balance/'; }



eval(__PACKAGE__->generate_accessors); die $@ if $@;

1
