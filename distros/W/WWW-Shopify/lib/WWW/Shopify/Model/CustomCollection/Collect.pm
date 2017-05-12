#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify;

package WWW::Shopify::Model::CustomCollection::Collect;
use parent "WWW::Shopify::Model::Item";

my $fields; sub fields { return $fields; } 
BEGIN { $fields = {
	"product_id" => new WWW::Shopify::Field::Relation::ReferenceOne("WWW::Shopify::Model::Product", 1),
	"collection_id" => new WWW::Shopify::Field::Relation::ReferenceOne("WWW::Shopify::Model::CustomCollection", 1),
	"created_at" => new WWW::Shopify::Field::Date(),
	"updated_at" => new WWW::Shopify::Field::Date(),
	"featured" => new WWW::Shopify::Field::Boolean(),
	"position" => new WWW::Shopify::Field::Int(),
	"id" => new WWW::Shopify::Field::Identifier(),
	# Same as position, but padded with 0s. Unfortunately, this is a lie, and is ocassionally a product name, arbitarily.
	"sort_value" => new WWW::Shopify::Field::String(),
}; }


my $queries; sub queries { return $queries; }
BEGIN { $queries = {
	collection_id => new WWW::Shopify::Query::Match('collection_id')
}; }

sub creation_minimal { return qw(product_id collection_id); }
sub creation_filled { return qw(position created_at); }
sub update_filled { return qw(updated_at); }

sub read_scope { return "read_products"; }
sub write_scope { return "write_products"; }

eval(__PACKAGE__->generate_accessors); die $@ if $@;

1;
