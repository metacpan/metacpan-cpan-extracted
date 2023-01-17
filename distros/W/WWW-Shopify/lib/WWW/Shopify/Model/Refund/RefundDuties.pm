#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify;

package WWW::Shopify::Model::Refund::RefundDuties;
use parent "WWW::Shopify::Model::NestedItem";

my $fields; sub fields { return $fields; } 
BEGIN { $fields = {
	"duties_id" => new WWW::Shopify::Field::Identifier(),
	"refund_type" => new WWW::Shopify::Field::String()
}; }

eval(__PACKAGE__->generate_accessors); die $@ if $@;

1
