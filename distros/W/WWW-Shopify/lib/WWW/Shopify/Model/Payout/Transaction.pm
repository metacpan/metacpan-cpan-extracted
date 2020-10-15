#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify;

package WWW::Shopify::Model::Payout::Transaction;
use parent "WWW::Shopify::Model::Item";

my $fields; sub fields { return $fields; } 
BEGIN { $fields = {
	"id" => new WWW::Shopify::Field::Identifier(),
	"amount" => new WWW::Shopify::Field::Money(),
	"currency" => new WWW::Shopify::Field::Currency(),
	"type" => new WWW::Shopify::Field::String::Enum([qw(charge refund dispute reserve adjustment credit debit payout payout_failure payout_cancellation)]),
	"test" => new WWW::Shopify::Field::Boolean(),
	"payout_id" => new WWW::Shopify::Field::Relation::Parent('WWW::Shopify::Model::Payout'),
	"payout_status" => new WWW::Shopify::Field::String(),
	"fee" => new WWW::Shopify::Field::Money(),
	"net" => new WWW::Shopify::Field::Money(),
	"source_id" => new WWW::Shopify::Field::BigInt(),
	"source_type" => new WWW::Shopify::Field::String::Enum([qw(charge refund dispute reserve adjustment payout)]),
	"source_order_transaction_id" => new WWW::Shopify::Field::Relation::ReferenceOne('WWW::Shopify::Model::Transaction'),
	"source_order_id" => new WWW::Shopify::Field::Relation::ReferenceOne('WWW::Shopify::Model::Order'),
	"processed_at" => new WWW::Shopify::Field::Date()
}; }
my $queries; sub queries { return $queries; }
BEGIN { $queries = {
	since_id => new WWW::Shopify::Query::LowerBound('id'),
	last_id => new WWW::Shopify::Query::UpperBound('id'),
	test => new WWW::Shopify::Query::Match('test'),
	payout_id => new WWW::Shopify::Query::Match('payout_id'),
	payout_status => new WWW::Shopify::Query::Enum('payout_status', [qw(scheduled in_transit paid failed cancelled)])
}; }

sub updatable { undef };
sub creatable { undef };

sub read_scope { return "read_orders"; }

eval(__PACKAGE__->generate_accessors); die $@ if $@;

1
