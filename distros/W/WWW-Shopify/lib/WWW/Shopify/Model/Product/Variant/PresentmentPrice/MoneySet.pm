#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify;

package WWW::Shopify::Model::Product::Variant::PresentmentPrice::MoneySet;
use parent 'WWW::Shopify::Model::NestedItem';

my $fields; sub fields { return $fields; } 
BEGIN { $fields = {
	"amount" => new WWW::Shopify::Field::Money(),
	"currency_code" => new WWW::Shopify::Field::Currency()
}; }

eval(__PACKAGE__->generate_accessors); die $@ if $@;

1
