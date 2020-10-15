#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify;

package WWW::Shopify::Model::Order::FulfillmentOrder::MerchantRequest;
use parent "WWW::Shopify::Model::NestedItem";

my $fields; sub fields { return $fields; } 
BEGIN { $fields = {
	"message" => new WWW::Shopify::Field::String(),
	"request_options" => new WWW::Shopify::Field::Freeform(),
	"kind" => new WWW::Shopify::Field::String()
} }

sub creation_minimal { return qw(status); }

eval(__PACKAGE__->generate_accessors); die $@ if $@;

1;
