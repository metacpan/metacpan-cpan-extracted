#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify;

package WWW::Shopify::Model::TenderTransaction;
use parent "WWW::Shopify::Model::Item";

my $fields; sub fields { return $fields; } 
BEGIN { $fields = {
	"id" => new WWW::Shopify::Field::Identifier(),
	"order_id" => new WWW::Shopify::Field::Relation::ReferenceOne('WWW::Shopify::Model::Order'),
	"user_id" => new WWW::Shopify::Field::Relation::ReferenceOne('WWW::Shopify::Model::User'),
	"amount" => new WWW::Shopify::Field::Money(),
	"currency" => new WWW::Shopify::Field::Currency(),
	"test" => new WWW::Shopify::Field::Boolean(),
	"processed_at" => new WWW::Shopify::Field::Date(),
	"remote_reference" => new WWW::Shopify::Field::String(),
	"payment_details" => new WWW::Shopify::Field::Relation::OwnOne('WWW::Shopify::Model::TenderTransaction::PaymentDetails'),
	"payment_method" => new WWW::Shopify::Field::String::Enum([qw(credit_card cash android_pay apple_pay google_pay samsung_pay shopify_pay amazon klarna paypal unknown other)])
}; }
my $queries; sub queries { return $queries; }
BEGIN { $queries = {
	since_id => new WWW::Shopify::Query::LowerBound('id'),
	processed_at_min => new WWW::Shopify::Query::LowerBound('processed_at'),
	processed_at_max => new WWW::Shopify::Query::UpperBound('processed_at'),
	processed_at => new WWW::Shopify::Query::Match('processed_at')
}; }

sub updatable { undef };
sub creatable { undef };

sub read_scope { return "read_orders"; }

eval(__PACKAGE__->generate_accessors); die $@ if $@;

1
