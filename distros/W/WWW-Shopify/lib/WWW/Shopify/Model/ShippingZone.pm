#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify;

package WWW::Shopify::Model::ShippingZone;
use parent "WWW::Shopify::Model::Item";

my $fields; sub fields { return $fields; } 
BEGIN { $fields = {
	"id" => new WWW::Shopify::Field::Identifier(),
	"name" => new WWW::Shopify::Field::String(),
	"countries" => new WWW::Shopify::Field::Relation::Many('WWW::Shopify::Model::Country'),
	"provinces" => new WWW::Shopify::Field::Relation::Many('WWW::Shopify::Model::Country::Province'),
	"carrier_shipping_rate_providers" => new WWW::Shopify::Field::Relation::Many('WWW::Shopify::Model::ShippingZone::CarrierServiceShippingRateProvider'),
	"price_based_shipping_rates" => new WWW::Shopify::Field::Relation::Many('WWW::Shopify::Model::ShippingZone::PriceBasedShippingRate'),
	"weight_based_shipping_rates" => new WWW::Shopify::Field::Relation::Many('WWW::Shopify::Model::ShippingZone::WeightBasedShippingRate')
} }

sub creatable { return undef; }
sub updatable { return undef; }
sub deletable { return undef; }
sub singlable { return undef; }

eval(__PACKAGE__->generate_accessors); die $@ if $@;

1;
