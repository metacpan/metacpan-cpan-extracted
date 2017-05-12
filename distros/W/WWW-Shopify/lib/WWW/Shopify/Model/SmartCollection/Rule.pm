#!/usr/bin/perl

use strict;
use warnings;

package WWW::Shopify::Model::SmartCollection::Rule;
use parent 'WWW::Shopify::Model::NestedItem';

my $fields; sub fields { return $fields; } 
BEGIN { $fields = {
	"column" => new WWW::Shopify::Field::String::Enum(["title", "type", "vendor", "tag", "weight", "variant_title", "variant_compare_at_price", "variant_inventory"]),
	"relation" => new WWW::Shopify::Field::String::Enum(["equals", "greater_than", "less_than", "starts_with", "ends_with", "contains"]),
	"condition" => new WWW::Shopify::Field::String(),
}; }

sub identifier { return ("column", "relation", "condition"); }

eval(__PACKAGE__->generate_accessors); die $@ if $@;

1;
