#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify;

package WWW::Shopify::Model::Order::TaxLine;
use parent "WWW::Shopify::Model::NestedItem";

my $fields; sub fields { return $fields; } 
BEGIN { $fields = {
	"price" => new WWW::Shopify::Field::Money(),
	"rate" => new WWW::Shopify::Field::Float(0.01, 0.5),
	"title" => new WWW::Shopify::Field::String::Words(1, 3),
	"price_set" => new WWW::Shopify::Field::Relation::OwnOne("WWW::Shopify::Model::Order::TaxLine::PriceSet")
}; }

sub identifier { return qw(title); }

eval(__PACKAGE__->generate_accessors); die $@ if $@;

1;
