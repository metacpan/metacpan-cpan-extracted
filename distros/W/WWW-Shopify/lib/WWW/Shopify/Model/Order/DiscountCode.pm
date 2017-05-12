#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify;

package WWW::Shopify::Model::Order::DiscountCode;
use parent "WWW::Shopify::Model::NestedItem";

my $fields; sub fields { return $fields; } 
BEGIN { $fields = {
	"code" => new WWW::Shopify::Field::String("[A-Z][0-9]{4,10}"),
	"amount" => new WWW::Shopify::Field::Money(),
	"type" => new WWW::Shopify::Field::String::Enum([qw(code percentage shipping)])
}; }
sub creatable { return undef; }
sub updatable { return undef; }
sub deletable { return undef; }

eval(__PACKAGE__->generate_accessors); die $@ if $@;

1
