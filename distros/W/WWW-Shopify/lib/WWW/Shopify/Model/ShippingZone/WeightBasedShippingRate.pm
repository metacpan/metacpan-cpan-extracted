#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify;

package WWW::Shopify::Model::ShippingZone::WeightBasedShippingRate;
use parent "WWW::Shopify::Model::NestedItem";

my $fields; sub fields { return $fields; } 
BEGIN { $fields = {
	"id" => new WWW::Shopify::Field::Identifier(),
	"shipping_zone_id" => new WWW::Shopify::Field::Relation::Parent('WWW::Shopify::Model::ShippingZone'),
	"name" => new WWW::Shopify::Field::String(),
	"price" => new WWW::Shopify::Field::Money(),
	"weight_high" => new WWW::Shopify::Field::Int(),
	"weight_low" => new WWW::Shopify::Field::Int()
} }

eval(__PACKAGE__->generate_accessors); die $@ if $@;

1;
