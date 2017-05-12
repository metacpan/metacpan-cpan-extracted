#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify;

package WWW::Shopify::Model::Order::Fulfillment;
use parent "WWW::Shopify::Model::Item";

my $fields; sub fields { return $fields; } 
BEGIN { $fields = {
	"created_at" => new WWW::Shopify::Field::Date(),
	"id" => new WWW::Shopify::Field::Identifier(),
	"order_id" => new WWW::Shopify::Field::Relation::Parent('WWW::Shopify::Model::Order'),
	"service" => new WWW::Shopify::Field::String::Enum(["manual", "automatic"]),
	"status" => new WWW::Shopify::Field::String::Enum(["success", "failure"]),
	"tracking_company" => new WWW::Shopify::Field::String(),
	"tracking_number" => new WWW::Shopify::Field::String(),
	"tracking_numbers" => new WWW::Shopify::Field::Freeform(),
	"tracking_url" => new WWW::Shopify::Field::String::URL(),
	"tracking_urls" => new WWW::Shopify::Field::Freeform(),
	"updated_at" => new WWW::Shopify::Field::Date(),
	"receipt" => new WWW::Shopify::Field::Relation::OwnOne('WWW::Shopify::Model::Order::Fulfillment::Receipt'),
	"line_items" => new WWW::Shopify::Field::Relation::Many('WWW::Shopify::Model::Order::Fulfillment::LineItem', 1),
	"notify_customer" => new WWW::Shopify::Field::Boolean()
}; }
sub cancellable { return 1; }
sub deletable { return undef; }

sub read_scope { return "read_orders"; }
sub write_scope { return "write_orders"; }

sub parent { return 'WWW::Shopify::Model::Order'; }

# Can be tracking number or tracking numbers.
#sub creation_minimal { return qw(tracking_number); }
sub creation_filled { return qw(id created_at service status); }
sub update_filled { return qw(updated_at); }

eval(__PACKAGE__->generate_accessors); die $@ if $@;

1;
