#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify;

package WWW::Shopify::Model::Order::LineItem::Location;
use parent "WWW::Shopify::Model::NestedItem";

my $fields; sub fields { return $fields; } 
BEGIN { $fields = {
	"id" => new WWW::Shopify::Field::Identifier(),
	"name" => new WWW::Shopify::Field::String(),
	"country_code" => new WWW::Shopify::Field::String::CountryCode(),
	"province_code" => new WWW::Shopify::Field::String::ProvinceCode(),
	"address1" => new WWW::Shopify::Field::String::Address(),
	"address2" => new WWW::Shopify::Field::String::Address(),
	"city" => new WWW::Shopify::Field::String::City(),
	"zip" => new WWW::Shopify::Field::String::Zip(),
}; }

eval(__PACKAGE__->generate_accessors); die $@ if $@;

1;
