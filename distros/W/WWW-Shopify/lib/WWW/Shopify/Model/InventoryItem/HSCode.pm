#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify;

package WWW::Shopify::Model::InventoryItem::HSCode;
use parent 'WWW::Shopify::Model::NestedItem';

my $fields; sub fields { return $fields; } 
BEGIN { $fields = {
	"harmonized_system_code" => new WWW::Shopify::Field::String(),
	"country_code" => new WWW::Shopify::Field::String::CountryCode()
}; }

eval(__PACKAGE__->generate_accessors); die $@ if $@;

1
