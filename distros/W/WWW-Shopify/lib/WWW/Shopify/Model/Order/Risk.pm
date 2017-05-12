#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify;

package WWW::Shopify::Model::Order::Risk;
use parent "WWW::Shopify::Model::Item";

sub parent { return 'WWW::Shopify::Model::Order'; }
my $fields; sub fields { return $fields; } 
BEGIN { $fields = {
	"order_id" => new WWW::Shopify::Field::Relation::Parent('WWW::Shopify::Model::Order'),
	"message" => new WWW::Shopify::Field::String(),
	"recommendation" => new WWW::Shopify::Field::String::Enum([qw(cancel investigate accept)]),
	"score" => new WWW::Shopify::Field::Float(),
	"id" => new WWW::Shopify::Field::Identifier(),
	"cause_cancel" => new WWW::Shopify::Field::Boolean(),
	"source" => new WWW::Shopify::Field::String(),
	"score" => new WWW::Shopify::Field::Float(),
	"display" => new WWW::Shopify::Field::Boolean()
}; }

sub countable { return undef; }
sub read_scope { return "read_orders"; }
sub write_scope { return "write_orders"; }

sub included_in_parent { return 0; }

eval(__PACKAGE__->generate_accessors); die $@ if $@;

1;
