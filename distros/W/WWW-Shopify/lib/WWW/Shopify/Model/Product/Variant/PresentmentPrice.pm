#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify;

package WWW::Shopify::Model::Product::Variant::PresentmentPrice;
use parent 'WWW::Shopify::Model::NestedItem';

my $fields; sub fields { return $fields; } 
BEGIN { $fields = {
	"price" => new WWW::Shopify::Field::Relation::OwnOne("WWW::Shopify::Model::Product::Variant::PresentmentPrice::MoneySet"),
	"compare_at_price" => new WWW::Shopify::Field::Relation::OwnOne("WWW::Shopify::Model::Product::Variant::PresentmentPrice::MoneySet")

}; }

eval(__PACKAGE__->generate_accessors); die $@ if $@;

1
