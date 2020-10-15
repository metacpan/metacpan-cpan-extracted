#!/usr/bin/perl

use strict;
use warnings;

package WWW::Shopify::Model::Product::Variant;
use parent 'WWW::Shopify::Model::Item';

my $fields; sub fields { return $fields; } 
BEGIN { $fields = {
	"fulfillment_service" => new WWW::Shopify::Field::String::Enum(["manual", "automatic"]),
	"grams" => new WWW::Shopify::Field::Int(),
	"weight" => new WWW::Shopify::Field::Float(),
	"weight_unit" => new WWW::Shopify::Field::String::Enum(["g", "kg", "oz", "lb"]),
	"inventory_management" => new WWW::Shopify::Field::String::Enum(["manual", "shopify"]),
	"inventory_policy" => new WWW::Shopify::Field::String("continue"),
	"inventory_quantity_adjustment" => new WWW::Shopify::Field::Int(),
	"option1" => new WWW::Shopify::Field::String::Words(),
	"option2" => new WWW::Shopify::Field::String::Words(),
	"option3" => new WWW::Shopify::Field::String::Words(),
	"position" => new WWW::Shopify::Field::Int(),
	"price" => new WWW::Shopify::Field::Money(),
	"requires_shipping" => new WWW::Shopify::Field::Boolean(),
	"sku" => new WWW::Shopify::Field::String(),
	"taxable" => new WWW::Shopify::Field::Boolean(),
	"tax_code" => new WWW::Shopify::Field::String(),
	"title" => new WWW::Shopify::Field::String::Words(),
	"compare_at_price" => new WWW::Shopify::Field::Money(),
	"inventory_quantity" => new WWW::Shopify::Field::Int(),
	"old_inventory_quantity" => new WWW::Shopify::Field::Int(),
	"barcode" => new WWW::Shopify::Field::String(),
	"metafields" => new WWW::Shopify::Field::Relation::Many("WWW::Shopify::Model::Metafield"),
	"id" => new WWW::Shopify::Field::Identifier(),
	"product_id" => new WWW::Shopify::Field::Relation::Parent('WWW::Shopify::Model::Product'),
	"created_at" => new WWW::Shopify::Field::Date(),
	"updated_at" => new WWW::Shopify::Field::Date(),
	"image_id" => new WWW::Shopify::Field::Relation::ReferenceOne("WWW::Shopify::Model::Product::Image"),
	"presentment_prices" => new WWW::Shopify::Field::Relation::Many("WWW::Shopify::Model::Product::Variant::PresentmentPrice"),
	"inventory_item_id" => new WWW::Shopify::Field::Relation::ReferenceOne("WWW::Shopify::Model::InventoryItem")
}; }

sub parent { return 'WWW::Shopify::Model::Product'; }

sub creation_minimal { return qw(option1 price); }
sub creation_filled { return qw(id created_at product_id); }
sub update_filled { return qw(updated_at); }
sub update_fields { return qw(fulfillment_service weight weight_unit inventory_management inventory_policy option1 option2 option3 position price requires_shipping sku taxable compare_at_price inventory_quantity barcode metafields); }

sub get_through_parent { return undef; }
sub update_through_parent { return undef; } 
sub delete_through_parent { return undef; }

sub read_scope { return "read_products"; }
sub write_scope { return "write_products"; }

eval(__PACKAGE__->generate_accessors); die $@ if $@;

1
