#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify;

package WWW::Shopify::Model::DraftOrder::AppliedDiscount;
use parent "WWW::Shopify::Model::NestedItem";


my $fields; sub fields { return $fields; } 

BEGIN { $fields = {
	"title" => new WWW::Shopify::Field::String(),
    "description" => new WWW::Shopify::Field::String(),
    "value" => new WWW::Shopify::Field::Float(),
    "value_type" => new WWW::Shopify::Field::String::Enum([qw(fixed_amount percentage)]),
    "amount" => new WWW::Shopify::Field::Float()
}; }

sub creatable { return undef; }
sub updatable { return undef; }
sub deletable { return undef; }

sub identifier { qw() }

eval(__PACKAGE__->generate_accessors); die $@ if $@;

1