#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify;

package WWW::Shopify::Model::Address;
use parent "WWW::Shopify::Model::NestedItem";

my $fields; sub fields { return $fields; } 
BEGIN { $fields = {
	"id" => new WWW::Shopify::Field::Identifier(),
	"address1" => new WWW::Shopify::Field::String::Address(),
	"address2" => new WWW::Shopify::Field::String::Address(),
	"city" => new WWW::Shopify::Field::String::City(),
	"company" => new WWW::Shopify::Field::String::Words(1, 3),
	"country" => new WWW::Shopify::Field::String::Country(),
	"first_name" => new WWW::Shopify::Field::String::FirstName(),
	"last_name" => new WWW::Shopify::Field::String::LastName(),
	"latitude" => new WWW::Shopify::Field::Float(-90, 90),
	"longitude" => new WWW::Shopify::Field::Float(-180, 180),
	"phone" => new WWW::Shopify::Field::String::Phone(),
	"province" => new WWW::Shopify::Field::String::Words(1),
	"zip" => new WWW::Shopify::Field::String::Zip(),
	"name" => new WWW::Shopify::Field::String::Words(1, 3),
	"country_code" => new WWW::Shopify::Field::String::CountryCode(),
	"province_code" => new WWW::Shopify::Field::String::ProvinceCode(),
	"default" => new WWW::Shopify::Field::Boolean()
}; }
sub plural { return 'addresses'; }
sub parent { return undef; }

# Addresses are always included in both customer and order objects.
sub included_in_parent { return 1; }

eval(__PACKAGE__->generate_accessors); die $@ if $@;

1;
