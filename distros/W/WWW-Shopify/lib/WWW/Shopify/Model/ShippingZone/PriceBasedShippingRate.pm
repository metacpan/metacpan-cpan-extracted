#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify;

package WWW::Shopify::Model::ShippingZone::PriceBasedShippingRate;
use parent "WWW::Shopify::Model::NestedItem";

my $fields; sub fields { return $fields; } 
BEGIN { $fields = {
	"id" => new WWW::Shopify::Field::Identifier(),
	"shipping_zone_id" => new WWW::Shopify::Field::Relation::Parent('WWW::Shopify::Model::ShippingZone'),
	"name" => new WWW::Shopify::Field::String(),
	"price" => new WWW::Shopify::Field::Money(),
	"max_order_subtotal" => new WWW::Shopify::Field::Money(),
	"min_order_subtotal" => new WWW::Shopify::Field::Money()
} }

eval(__PACKAGE__->generate_accessors); die $@ if $@;

1;
