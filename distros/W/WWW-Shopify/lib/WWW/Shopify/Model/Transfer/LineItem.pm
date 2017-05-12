#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify;

package WWW::Shopify::Model::Transfer::LineItem;
use parent 'WWW::Shopify::Model::NestedItem';

my $fields; sub fields { return $fields; } 
BEGIN { $fields = {
	"id" => new WWW::Shopify::Field::Identifier(),
	"product_variant_id" => new WWW::Shopify::Field::Relation::ReferenceOne('WWW::Shopify::Model::Product::Variant'),
	"quantity" => new WWW::Shopify::Field::Int(),
	"created_at" => new WWW::Shopify::Field::Date(),
	"updated_at" => new WWW::Shopify::Field::Date(),
	"product_id" => new WWW::Shopify::Field::Relation::ReferenceOne('WWW::Shopify::Model::Product'),
	"cancelled_quantity" => new WWW::Shopify::Field::Int(),
	"accepted_quantity" => new WWW::Shopify::Field::Int(),
	"rejected_quantity" => new WWW::Shopify::Field::Int(),
	"remaining_quantity" => new WWW::Shopify::Field::Int()
}; }

eval(__PACKAGE__->generate_accessors); die $@ if $@;

1;
