#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify;

package WWW::Shopify::Model::Order::LineItem::Duties;
use parent "WWW::Shopify::Model::NestedItem";

my $fields; sub fields { return $fields; } 
BEGIN { $fields = {
	"id" => new WWW::Shopify::Field::Identifier(),
	"harmonized_system_code" => new WWW::Shopify::Field::Text(),
	"country_code_of_origin" => new WWW::Shopify::Field::String::CountryCode(),
	"shop_money" => new WWW::Shopify::Field::Relation::OwnOne("WWW::Shopify::Model::Order::LineItem::Duties::PriceSet"),
	"presentment_money" => new WWW::Shopify::Field::Relation::OwnOne("WWW::Shopify::Model::Order::LineItem::Duties::PriceSet"),
	"tax_lines" => new WWW::Shopify::Field::Relation::Many("WWW::Shopify::Model::Order::LineItem::Duties::TaxLine"),
	"admin_graphql_api_id" => new WWW::Shopify::Field::String()
}; }

eval(__PACKAGE__->generate_accessors); die $@ if $@;

1
