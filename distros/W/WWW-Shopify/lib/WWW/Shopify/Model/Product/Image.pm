#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify;

package WWW::Shopify::Model::Product::Image;
use parent "WWW::Shopify::Model::NestedItem";

my $fields; sub fields { return $fields; } 
BEGIN { $fields = {
	"id" => new WWW::Shopify::Field::Identifier(),
	"position" => new WWW::Shopify::Field::Int(),
	"src" => new WWW::Shopify::Field::String::URL::Image(),
	"attachment" => new WWW::Shopify::Field::Text(),
	"filename" => new WWW::Shopify::Field::String(),
	"product_id" => new WWW::Shopify::Field::Relation::Parent('WWW::Shopify::Model::Product'),
	"created_at" => new WWW::Shopify::Field::Date(),
	"updated_at" => new WWW::Shopify::Field::Date(),
	"metafields" => new WWW::Shopify::Field::Relation::Many('WWW::Shopify::Model::Metafield'),
	"variant_ids" => new WWW::Shopify::Field::Freeform::Array()
}; }

#sub creation_minimal { return qw(filename); }
sub creation_filled { return qw(id created_at ); }
sub update_filled { return qw(updated_at); } 
sub update_fields { return qw(metafields position variant_ids); }

sub read_scope { return "read_products"; }
sub write_scope { return "write_products"; }

eval(__PACKAGE__->generate_accessors); die $@ if $@;

1
