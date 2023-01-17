#!/usr/bin/perl

use strict;
use warnings;

package WWW::Shopify::Model::InventoryLevel;
use parent "WWW::Shopify::Model::Item";

my $fields; sub fields { return $fields; } 
BEGIN { $fields = {
	"available" => new WWW::Shopify::Field::Int(),
	"available_adjustment" => new WWW::Shopify::Field::Int(),
	"inventory_item_id" => new WWW::Shopify::Field::Relation::ReferenceOne("WWW::Shopify::Model::InventoryItem"),
	"location_id" => new WWW::Shopify::Field::Relation::ReferenceOne("WWW::Shopify::Model::Location"),
	"updated_at" => new WWW::Shopify::Field::Date()
}; }
my $queries; sub queries { return $queries; }
BEGIN { $queries = {
	inventory_item_ids => new WWW::Shopify::Query::MultiMatch('inventory_item_id'),
	location_ids => new WWW::Shopify::Query::MultiMatch('location_id')
}; }

sub actions { qw(set connect adjust) }
sub identifier { qw(inventory_item_id location_id) }
sub read_scope { return "read_inventory"; }
sub write_scope { return "write_inventory"; }

eval(__PACKAGE__->generate_accessors); die $@ if $@;

1
