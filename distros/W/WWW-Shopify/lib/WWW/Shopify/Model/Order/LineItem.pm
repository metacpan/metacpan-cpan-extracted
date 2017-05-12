#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify;

package WWW::Shopify::Model::Order::LineItem;
use parent "WWW::Shopify::Model::NestedItem";

my $fields; sub fields { return $fields; } 
BEGIN { $fields = {
	"fulfillable_quantity" => new WWW::Shopify::Field::Int(),
	"fulfillment_service" => new WWW::Shopify::Field::String::Enum(["automatic", "manual"]),
	"fulfillment_status" => new WWW::Shopify::Field::String(),
	"grams" => new WWW::Shopify::Field::Int(),
	"id" => new WWW::Shopify::Field::Identifier(),
	"price" => new WWW::Shopify::Field::Money(),
	# FINALLY
	"total_discount" => new WWW::Shopify::Field::Money(),
	# These are not always filled out. If a product is deleted, these are null.
	"product_id" => new WWW::Shopify::Field::Relation::ReferenceOne('WWW::Shopify::Model::Product', 1),
	"variant_id" => new WWW::Shopify::Field::Relation::ReferenceOne('WWW::Shopify::Model::Product::Variant', 1),
	#
	"gift_card" => new WWW::Shopify::Field::Boolean(),
	"quantity" => new WWW::Shopify::Field::Int(1, 20),
	"requires_shipping" => new WWW::Shopify::Field::Boolean(),
	"product_exists" => new WWW::Shopify::Field::Boolean(),
	"sku" => new WWW::Shopify::Field::String(),
	"title" => new WWW::Shopify::Field::String::Words(1, 3),
	"variant_title" => new WWW::Shopify::Field::String::Words(1,3),
	"vendor" => new WWW::Shopify::Field::String(),
	"name" => new WWW::Shopify::Field::String::Words(1, 3),
	"properties" => new WWW::Shopify::Field::Relation::Many("WWW::Shopify::Model::Order::LineItem::Property"),
	"tax_lines" => new WWW::Shopify::Field::Relation::Many("WWW::Shopify::Model::Order::LineItem::TaxLine"),
	"origin_location" => new WWW::Shopify::Field::Relation::OwnOne("WWW::Shopify::Model::Order::LineItem::Location"),
	"destination_location" => new WWW::Shopify::Field::Relation::OwnOne("WWW::Shopify::Model::Order::LineItem::Location"),
	"taxable" => new WWW::Shopify::Field::Boolean(),
	"variant_inventory_management" => new WWW::Shopify::Field::String::Enum(["shopify", "manual"]) };
}

sub singular { return 'line_item'; }

eval(__PACKAGE__->generate_accessors); die $@ if $@;

1
