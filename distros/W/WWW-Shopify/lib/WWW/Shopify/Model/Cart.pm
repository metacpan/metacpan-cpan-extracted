#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify;

package WWW::Shopify::Model::Cart;
use parent 'WWW::Shopify::Model::Item';

my $fields; sub fields { return $fields; } 
BEGIN { $fields = {
	"note" => new WWW::Shopify::Field::String::Words(1, 20),
	"token" => new WWW::Shopify::Field::String::Hash(),
	"line_items" => new WWW::Shopify::Field::Relation::Many('WWW::Shopify::Model::Cart::LineItem', 0, 10),
	"id" => new WWW::Shopify::Field::Identifier(),
	"updated_at" => new WWW::Shopify::Field::Date()
}; }

sub needs_login { 1; }

eval(__PACKAGE__->generate_accessors); die $@ if $@;

1;
