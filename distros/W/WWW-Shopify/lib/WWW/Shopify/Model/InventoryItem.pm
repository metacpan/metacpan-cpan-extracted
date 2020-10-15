#!/usr/bin/perl

use strict;
use warnings;

package WWW::Shopify::Model::InventoryItem;
use parent "WWW::Shopify::Model::Item";

my $fields; sub fields { return $fields; } 
BEGIN { $fields = {
	"id" => new WWW::Shopify::Field::Identifier(),
	"sku" => new WWW::Shopify::Field::String(),
	"tracked" => new WWW::Shopify::Field::Boolean(),
	"cost" => new WWW::Shopify::Field::Money(),
	"updated_at" => new WWW::Shopify::Field::Date(),
	"created_at" => new WWW::Shopify::Field::Date(),
	"country_code_of_origin" => new WWW::Shopify::Field::String::CountryCode(),
	"province_code_of_origin" => new WWW::Shopify::Field::String::ProvinceCode(),
	"country_harmonized_system_codes" => new WWW::Shopify::Field::Relation::Many('WWW::Shopify::Model::InventoryItem::HSCode'),
	"harmonized_system_code" => new WWW::Shopify::Field::String(),
	"requires_shipping" => new WWW::Shopify::Field::Boolean()
}; }
my $queries; sub queries { return $queries; }
BEGIN { $queries = {
	ids => new WWW::Shopify::Query::MultiMatch('id'),
}; }

sub read_scope { return "read_inventory"; }
sub write_scope { return "write_inventory"; }

eval(__PACKAGE__->generate_accessors); die $@ if $@;

1
