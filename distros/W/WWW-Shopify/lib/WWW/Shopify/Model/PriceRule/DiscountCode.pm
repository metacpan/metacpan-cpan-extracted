#!/usr/bin/perl

use strict;
use warnings;

package WWW::Shopify::Model::PriceRule::DiscountCode;
use parent "WWW::Shopify::Model::Item";

my $fields; sub fields { return $fields; } 
BEGIN { $fields = {
	"id" => new WWW::Shopify::Field::Identifier(),
	"price_rule_id" => new WWW::Shopify::Field::Relation::Parent('WWW::Shopify::Model::PriceRule'),
	"code" => new WWW::Shopify::Field::String(),
	"created_at" => new WWW::Shopify::Field::Date(),
	"updated_at" => new WWW::Shopify::Field::Date(),
	"usage_count" => new WWW::Shopify::Field::Int()
}; }

sub parent { 'WWW::Shopify::Model::PriceRule'; }
sub creation_filled { return qw(id created_at updated_at); }
sub throws_webhooks { return 1; }

sub read_scope { return "read_price_rules"; }
sub write_scope { return "write_price_rules"; }
sub countable { undef; }

eval(__PACKAGE__->generate_accessors); die $@ if $@;

1
