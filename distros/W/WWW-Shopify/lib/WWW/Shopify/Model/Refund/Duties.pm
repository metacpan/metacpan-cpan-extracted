#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify;

package WWW::Shopify::Model::Refund::Duties;
use parent "WWW::Shopify::Model::NestedItem";

my $fields; sub fields { return $fields; } 
BEGIN { $fields = {
	"id" => new WWW::Shopify::Field::Identifier(),
	"amount_set" => new WWW::Shopify::Field::Relation::OwnOne("WWW::Shopify::Model::Refund::Duties::PriceSet"),
}; }

eval(__PACKAGE__->generate_accessors); die $@ if $@;

1
