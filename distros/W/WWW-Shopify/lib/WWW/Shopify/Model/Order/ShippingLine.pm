#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify;

package WWW::Shopify::Model::Order::ShippingLine;
use parent "WWW::Shopify::Model::NestedItem";

my $fields; sub fields { return $fields; } 
BEGIN { $fields = {
	"code" => new WWW::Shopify::Field::String::Words(1, 3),
	"price" => new WWW::Shopify::Field::Money(),
	"source" => new WWW::Shopify::Field::String("shopify"),
	"title" => new WWW::Shopify::Field::String::Words(1, 3),
	"phone" => new WWW::Shopify::Field::String(),
	"requested_fulfillment_service_id" => new WWW::Shopify::Field::Int(),
	"delivery_category" => new WWW::Shopify::Field::String(),
	"carrier_identifier" => new WWW::Shopify::Field::String(),
	"discounted_price" => new WWW::Shopify::Field::Money(),
	"tax_lines" => new WWW::Shopify::Field::Relation::Many('WWW::Shopify::Model::Order::ShippingLine::TaxLine'),
	
	"price_set" => new WWW::Shopify::Field::Relation::OwnOne("WWW::Shopify::Model::Order::ShippingLine::PriceSet"),
	"discounted_price_set" => new WWW::Shopify::Field::Relation::OwnOne("WWW::Shopify::Model::Order::ShippingLine::PriceSet"),
};
}

sub identifier { return ("code"); }

eval(__PACKAGE__->generate_accessors); die $@ if $@;

1;
