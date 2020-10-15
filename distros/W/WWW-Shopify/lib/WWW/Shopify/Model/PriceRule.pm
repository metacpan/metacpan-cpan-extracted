#!/usr/bin/perl

use strict;
use warnings;

package WWW::Shopify::Model::PriceRule;
use parent "WWW::Shopify::Model::Item";

my $fields; sub fields { return $fields; } 
BEGIN { $fields = {
	"id" => new WWW::Shopify::Field::Identifier(),
	"title" => new WWW::Shopify::Field::String(),
	"created_at" => new WWW::Shopify::Field::Date(),
	"updated_at" => new WWW::Shopify::Field::Date(),
	"starts_at" => new WWW::Shopify::Field::Date(),
	"ends_at" => new WWW::Shopify::Field::Date(),
	"once_per_customer" => new WWW::Shopify::Field::Boolean(),
	"usage_limit" => new WWW::Shopify::Field::Int(),
	"value" => new WWW::Shopify::Field::Float(),
	"value_type" => new WWW::Shopify::Field::String::Enum([qw(fixed_amount)]),
	"alloction_method" => new WWW::Shopify::Field::String::Enum([qw(fixed_amount)]),
	"target_selection" => new WWW::Shopify::Field::String(),
	"target_type" => new WWW::Shopify::Field::String(),
	"entitled_product_ids" => new WWW::Shopify::Field::Freeform::Array(),
	"entitled_variant_ids" => new WWW::Shopify::Field::Freeform::Array(),
	"entitled_collection_ids" => new WWW::Shopify::Field::Freeform::Array(),
	"entitled_country_ids" => new WWW::Shopify::Field::Freeform::Array(),
	"prerequisite_subtotal_range" => new WWW::Shopify::Field::Freeform::Hash(),
	"prerequisite_shipping_price_range" => new WWW::Shopify::Field::Freeform::Hash(),
	"prerequisite_saved_search_ids" => new WWW::Shopify::Field::Freeform::Array(),
	"prerequisite_customer_ids" => new WWW::Shopify::Field::Freeform::Array()
}; }

# Of course they're not.
sub countable { undef; }
sub creation_filled { return qw(id created_at updated_at); }
# Odd, even without an update method, it still has an updated at.
sub throws_webhooks { return 1; }

sub read_scope { return "read_price_rules"; }
sub write_scope { return "write_price_rules"; }

eval(__PACKAGE__->generate_accessors); die $@ if $@;

1
