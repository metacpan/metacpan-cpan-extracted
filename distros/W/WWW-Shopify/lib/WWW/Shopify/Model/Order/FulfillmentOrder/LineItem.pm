#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify;

package WWW::Shopify::Model::Order::FulfillmentOrder::LineItem;
use parent 'WWW::Shopify::Model::NestedItem';

my $fields; sub fields { return $fields; } 
BEGIN { $fields = {
	"id" => new WWW::Shopify::Field::Identifier(),
	"fulfillment_order_id" => new WWW::Shopify::Field::Relation::Parent(),
	"line_item_id" => new WWW::Shopify::Field::Relation::ReferenceOne('WWW::Shopify::Model::Order::LineItem'),
	"inventory_item_id" => new WWW::Shopify::Field::Relation::ReferenceOne('WWW::Shopify::Model::InventoryItem'),
	"quantity" => new WWW::Shopify::Field::Int(),
	"fulfillable_quantity" => new WWW::Shopify::Field::Int(),
	"inventory_item_id" => new WWW::Shopify::Field::Relation::ReferenceOne('WWW::Shopify::Model::Product::Variant')
} }

eval(__PACKAGE__->generate_accessors); die $@ if $@;

1;
