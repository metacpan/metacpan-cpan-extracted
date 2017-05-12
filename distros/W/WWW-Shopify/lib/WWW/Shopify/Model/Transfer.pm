#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify;

package WWW::Shopify::Model::Transfer;
use parent 'WWW::Shopify::Model::Item';

my $fields; sub fields { return $fields; } 
BEGIN { $fields = {
	"id" => new WWW::Shopify::Field::Identifier(),
	"created_at" => new WWW::Shopify::Field::Date(),
	"updated_at" => new WWW::Shopify::Field::Date(),
	"archived_at" => new WWW::Shopify::Field::Date(),
	"expected_arrival" => new WWW::Shopify::Field::Date(),
	"placed_at" => new WWW::Shopify::Field::Date(),
	"status" => new WWW::Shopify::Field::String(),
	"name" => new WWW::Shopify::Field::String(),
	"tags" => new WWW::Shopify::Field::String(),
	"line_items" => new WWW::Shopify::Field::Relation::Many('WWW::Shopify::Model::Transfer::LineItem'),
}; }

sub singular { return 'inventory_transfer'; }
sub url_singular { return 'transfer'; }
sub url_plural { return 'tranfers'; }

sub needs_login { return 1; } 

eval(__PACKAGE__->generate_accessors); die $@ if $@;

1;
