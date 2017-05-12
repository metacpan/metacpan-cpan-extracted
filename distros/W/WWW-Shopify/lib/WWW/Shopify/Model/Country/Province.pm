#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify;

package WWW::Shopify::Model::Country::Province;
use parent "WWW::Shopify::Model::NestedItem";

my $fields; sub fields { return $fields; } 
BEGIN { $fields = {
	"code" => new WWW::Shopify::Field::String::ProvinceCode(),
	"id" => new WWW::Shopify::Field::Identifier(),
	"name" => new WWW::Shopify::Field::String::Province(),
	"tax_name" => new WWW::Shopify::Field::String(),
	"tax_type" => new WWW::Shopify::Field::String(),
	"tax_percentage" => new WWW::Shopify::Field::Float(),
	"tax" => new WWW::Shopify::Field::Float(),
	"country_id" => new WWW::Shopify::Field::Relation::Parent("WWW::Shopify::Model::Country")
	
}; }
my $queries; sub queries { return $queries; }
BEGIN { $queries = {
	since_id => new WWW::Shopify::Query::LowerBound('id')
}; }

sub creation_minimal { return qw(code); }

eval(__PACKAGE__->generate_accessors); die $@ if $@;

1
