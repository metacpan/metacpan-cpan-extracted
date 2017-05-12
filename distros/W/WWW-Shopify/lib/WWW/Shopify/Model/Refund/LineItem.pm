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
	"quantity" => new WWW::Shopify::Field::Int(),
}; }

sub singular() { return 'refund_line_item'; }

eval(__PACKAGE__->generate_accessors); die $@ if $@;

1
