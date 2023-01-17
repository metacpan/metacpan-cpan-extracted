#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify;

package WWW::Shopify::Model::Order::FulfillmentOrder;
use parent "WWW::Shopify::Model::Item";

my $fields; sub fields { return $fields; } 
BEGIN { $fields = {
	"id" => new WWW::Shopify::Field::Identifier(),
	"shop_id" => new WWW::Shopify::Field::Relation::ReferenceOne('WWW::Shopify::Model::Shop'),
	"order_id" => new WWW::Shopify::Field::Relation::Parent('WWW::Shopify::Model::Order'),
	"status" => new WWW::Shopify::Field::String::Enum([qw(open in_progress cancelled incomplete closed)]),
	"destination" => new WWW::Shopify::Field::Relation::OwnOne('WWW::Shopify::Model::Order::FulfillmentOrder::Destination'),
	"line_items" => new WWW::Shopify::Field::Relation::Many('WWW::Shopify::Model::Order::FulfillmentOrder::LineItem'),
	"request_status" => new WWW::Shopify::Field::String::Enum([qw(unsubmitted submitted accepted rejected cancelation_requested cancelation_accepted cancelation_rejected closed)]),
	"supported_actions" => new WWW::Shopify::Field::String(),
	"merchant_requests" => new WWW::Shopify::Field::Relation::Many('WWW::Shopify::Model::Order::FulfillmentOrder::MerchantRequest'),
	"assigned_location" => new WWW::Shopify::Field::Relation::OwnOne('WWW::Shopify::Model::Location')
} }

sub url_plural { return 'fulfillment_orders'; }
sub read_scope { return "read_assigned_fulfillment_orders,"; }
sub write_scope { return "write_assigned_fulfillment_orders,"; }
sub parent { return 'WWW::Shopify::Model::Order'; }
sub countable { return 0; }
sub creatable { return 0; }
sub actions { return qw(cancel close hold move open release_hold reschedule set_fulfillment_orders_deadline); }

sub included_in_parent { return 0; }

sub creation_minimal { return qw(status); }

eval(__PACKAGE__->generate_accessors); die $@ if $@;

1;
