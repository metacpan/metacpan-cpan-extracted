#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify;

package WWW::Shopify::Model::Product::Option;
use parent "WWW::Shopify::Model::NestedItem";

my $fields; sub fields { return $fields; } 
BEGIN { $fields = {
	"name" => new WWW::Shopify::Field::String::Words(1),
	"id" => new WWW::Shopify::Field::Identifier(),
	"position" => new WWW::Shopify::Field::Int(1, 3),
	"product_id" => new WWW::Shopify::Field::Relation::Parent('WWW::Shopify::Model::Product'),
	"values" => new WWW::Shopify::Field::Freeform::Array()
}; }

sub creation_minimal { return qw(name); }
sub creation_filled { return qw(id position); }

eval(__PACKAGE__->generate_accessors); die $@ if $@;

1
