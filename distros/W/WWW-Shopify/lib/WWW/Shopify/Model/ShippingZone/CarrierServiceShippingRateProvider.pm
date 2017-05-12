#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify;

package WWW::Shopify::Model::ShippingZone::CarrierServiceShippingRateProvider;
use parent "WWW::Shopify::Model::NestedItem";

my $fields; sub fields { return $fields; } 
BEGIN { $fields = {
	"id" => new WWW::Shopify::Field::Identifier(),
	"carrier_service_id" => new WWW::Shopify::Field::Relation::ReferenceOne('WWW::Shopify::Model::CarrierService'),
	"country_id" => new WWW::Shopify::Field::Relation::ReferenceOne('WWW::Shopify::Model::Country'),
	"flat_modifier" => new WWW::Shopify::Field::Float(),
	"percent_modifier" => new WWW::Shopify::Field::Float(),
	"service_filter" => new WWW::Shopify::Field::Freeform::Hash(),
	"shipping_zone_id" => new WWW::Shopify::Field::Relation::Parent('WWW::Shopify::Model::ShippingZone')
} }


eval(__PACKAGE__->generate_accessors); die $@ if $@;

1;
