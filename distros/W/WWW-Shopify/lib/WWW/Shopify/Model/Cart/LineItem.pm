#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify;

package WWW::Shopify::Model::Cart::LineItem;

use parent 'WWW::Shopify::Model::NestedItem';

my $fields; sub fields { return $fields; } 
BEGIN { $fields = {
	"grams" => new WWW::Shopify::Field::Int(1, 2000),
	"id" => new WWW::Shopify::Field::Identifier(),
	"price" => new WWW::Shopify::Field::Money(),
	"line_price" => new WWW::Shopify::Field::Money(),
	"quantity" => new WWW::Shopify::Field::Int(1, 20),
	"sku" => new WWW::Shopify::Field::String(),
	"title" => new WWW::Shopify::Field::String::Words(1, 3),
	"variant_id" => new WWW::Shopify::Field::Relation::ReferenceOne('WWW::Shopify::Model::Product::Variant'),
	"vendor" => new WWW::Shopify::Field::String()
}; }
sub creation_minimal { return qw(title); }
sub creation_filled { return qw(id); }

sub singular() { return 'line_item'; }

eval(__PACKAGE__->generate_accessors); die $@ if $@;

1;
