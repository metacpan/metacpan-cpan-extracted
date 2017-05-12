#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify;

package WWW::Shopify::Model::Checkout;
use parent "WWW::Shopify::Model::Item";

my $fields; sub fields { return $fields; } 
BEGIN { $fields = {
	"buyer_accepts_marketing" => new WWW::Shopify::Field::Boolean(),
	"cart_token" => new WWW::Shopify::Field::String::Hash(),
	"created_at" => new WWW::Shopify::Field::Date(),
	"email" => new WWW::Shopify::Field::String::Email(),
	"id" => new WWW::Shopify::Field::Identifier(),
	"token" => new WWW::Shopify::Field::String::Hash(),
	"abandoned_checkout_url" => new WWW::Shopify::Field::String::URL(),
	"landing_site" => new WWW::Shopify::Field::String::URL(),
	"referring_site" => new WWW::Shopify::Field::String::URL(),
	"note" => new WWW::Shopify::Field::String(),
	"updated_at" => new WWW::Shopify::Field::Date(),
	"source_name" => new WWW::Shopify::Field::String::Enum(["web", "pos"]),
	"subtotal_price" => new WWW::Shopify::Field::Money(),
	"taxes_included" => new WWW::Shopify::Field::Boolean(),
	"total_discounts" => new WWW::Shopify::Field::Money(),
	"total_line_items_price" => new WWW::Shopify::Field::Money(),
	"total_price" => new WWW::Shopify::Field::Money(),
	"total_tax" => new WWW::Shopify::Field::Money(),
	"total_weight" => new WWW::Shopify::Field::Float(),
	"note_attributes" => new WWW::Shopify::Field::Relation::Many('WWW::Shopify::Model::Checkout::NoteAttribute'),
	"discount_codes" => new WWW::Shopify::Field::Relation::Many('WWW::Shopify::Model::Checkout::DiscountCode'),
	"tax_lines" => new WWW::Shopify::Field::Relation::Many('WWW::Shopify::Model::Checkout::TaxLine'),
	"shipping_lines" => new WWW::Shopify::Field::Relation::Many('WWW::Shopify::Model::Checkout::ShippingLine'),
	"line_items" => new WWW::Shopify::Field::Relation::Many('WWW::Shopify::Model::Checkout::LineItem'),
	"billing_address" => new WWW::Shopify::Field::Relation::OwnOne('WWW::Shopify::Model::Address'),
	"shipping_address" => new WWW::Shopify::Field::Relation::OwnOne('WWW::Shopify::Model::Address'),
	"customer" => new WWW::Shopify::Field::Relation::OwnOne('WWW::Shopify::Model::Customer')};
}

my $queries; sub queries { return $queries; }
BEGIN { $queries = {
	created_at_min => new WWW::Shopify::Query::LowerBound('created_at'),
	created_at_max => new WWW::Shopify::Query::UpperBound('created_at'),
	updated_at_min => new WWW::Shopify::Query::LowerBound('updated_at'),
	updated_at_max => new WWW::Shopify::Query::UpperBound('updated_at'),
	status => new WWW::Shopify::Query::Enum('status', ['open', 'closed']),
	since_id => new WWW::Shopify::Query::LowerBound('id')
}; }


sub creatable { return undef; }
sub updatable { return undef; }
sub deletable { return undef; }

eval(__PACKAGE__->generate_accessors); die $@ if $@;

1;
