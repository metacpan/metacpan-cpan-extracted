#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify;

package WWW::Shopify::Model::Refund::LineItem;
use parent "WWW::Shopify::Model::NestedItem";

my $fields; sub fields { return $fields; } 
BEGIN { $fields = {
	"id" => new WWW::Shopify::Field::Identifier(),
	"line_item" => new WWW::Shopify::Field::Relation::OwnOne('WWW::Shopify::Model::Order::LineItem'),
	"line_item_id" => new WWW::Shopify::Field::Relation::ReferenceOne('WWW::Shopify::Model::Order::LineItem'),
	"location_id" => new WWW::Shopify::Field::Relation::ReferenceOne('WWW::Shopify::Model::Location'),
	"restock_type" => new WWW::Shopify::Field::String::Enum([qw(legacy_restock)]),
	"subtotal" => new WWW::Shopify::Field::Money(),
	"subtotal_set" => new WWW::Shopify::Field::Relation::OwnOne("WWW::Shopify::Model::Refund::LineItem::PriceSet"),
	"total_tax" => new WWW::Shopify::Field::Money(),
	"total_tax_set" => new WWW::Shopify::Field::Relation::OwnOne("WWW::Shopify::Model::Refund::LineItem::PriceSet"),
	"quantity" => new WWW::Shopify::Field::Int(),
}; }

sub singular() { return 'refund_line_item'; }

eval(__PACKAGE__->generate_accessors); die $@ if $@;

1
