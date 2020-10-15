#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify;

package WWW::Shopify::Model::Order::LineItem::DiscountAllocation;
use parent "WWW::Shopify::Model::NestedItem";

my $fields; sub fields { return $fields; } 
BEGIN { $fields = {
	"amount" => new WWW::Shopify::Field::Money(),
	"amount_set" => new WWW::Shopify::Field::Relation::OwnOne("WWW::Shopify::Model::Order::LineItem::DiscountAllocation::PriceSet"),
	"discount_application_index" => new WWW::Shopify::Field::Int()
}; }
sub creatable { return undef; }
sub updatable { return undef; }
sub deletable { return undef; }

eval(__PACKAGE__->generate_accessors); die $@ if $@;

1
