#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify;

package WWW::Shopify::Model::Order::DiscountApplication;
use parent "WWW::Shopify::Model::NestedItem";

my $fields; sub fields { return $fields; } 
BEGIN { $fields = {
	"allocation_method" => new WWW::Shopify::Field::String::Enum([qw(across each one)]),
	"code" => new WWW::Shopify::Field::String(),
	"description" => new WWW::Shopify::Field::String(),
	"target_selection" => new WWW::Shopify::Field::String::Enum([qw(all entitled explicit)]),
	"target_type" => new WWW::Shopify::Field::String::Enum([qw(line_item shipping_line)]),
	"title" => new WWW::Shopify::Field::String(),
	"type" => new WWW::Shopify::Field::String::Enum([qw(manual discount_code script)]),
	"value" => new WWW::Shopify::Field::Float(),
	"value_type" => new WWW::Shopify::Field::String::Enum([qw(fixed_amount percentage)])
}; }
sub creatable { return undef; }
sub updatable { return undef; }
sub deletable { return undef; }

sub identifier { qw() }

eval(__PACKAGE__->generate_accessors); die $@ if $@;

1
