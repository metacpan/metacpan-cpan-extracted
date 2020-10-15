#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify;

package WWW::Shopify::Model::Refund::OrderAdjustment;
use parent "WWW::Shopify::Model::NestedItem";

my $fields; sub fields { return $fields; } 
BEGIN { $fields = {
	"id" => new WWW::Shopify::Field::Identifier(),
	"order_id" => new WWW::Shopify::Field::Relation::ReferenceOne('WWW::Shopify::Model::Order'),
	"refund_id" => new WWW::Shopify::Field::Relation::Parent('WWW::Shopify::Model::Refund'),
	"amount" => new WWW::Shopify::Field::Money(),
	"amount_set" => new WWW::Shopify::Field::Relation::OwnOne("WWW::Shopify::Model::Refund::OrderAdjustment::PriceSet"),
	"tax_amount" => new WWW::Shopify::Field::Money(),
	"tax_amount_set" => new WWW::Shopify::Field::Relation::OwnOne("WWW::Shopify::Model::Refund::OrderAdjustment::PriceSet"),
	"kind" => new WWW::Shopify::Field::String(),
	"reason" => new WWW::Shopify::Field::String()
}; }

eval(__PACKAGE__->generate_accessors); die $@ if $@;

1
