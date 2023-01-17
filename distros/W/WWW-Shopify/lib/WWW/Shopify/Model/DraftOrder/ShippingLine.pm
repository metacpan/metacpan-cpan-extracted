#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify;

package WWW::Shopify::Model::DraftOrder::ShippingLine;
use parent "WWW::Shopify::Model::NestedItem";

my $fields; sub fields { return $fields; } 
BEGIN { $fields = {
  "custom" => new WWW::Shopify::Field::Boolean(),
  "handle" => new WWW::Shopify::Field::String(),
	"price" => new WWW::Shopify::Field::Money(),
	"title" => new WWW::Shopify::Field::String::Words(1, 3)
};
}

sub identifier { return ("handle"); }

eval(__PACKAGE__->generate_accessors); die $@ if $@;

1;
