#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify;

package WWW::Shopify::Model::Order::PriceSet;
use parent 'WWW::Shopify::Model::NestedItem';

my $fields; sub fields { return $fields; } 
BEGIN { $fields = {
	"shop_money" => new WWW::Shopify::Field::Relation::OwnOne("WWW::Shopify::Model::Order::PriceSet::MoneySet"),
	"presentment_money" => new WWW::Shopify::Field::Relation::OwnOne("WWW::Shopify::Model::Order::PriceSet::MoneySet")

}; }

eval(__PACKAGE__->generate_accessors); die $@ if $@;

1
