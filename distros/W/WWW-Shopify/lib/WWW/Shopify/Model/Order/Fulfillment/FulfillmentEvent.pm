#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify;

package WWW::Shopify::Model::Order::Fulfillment::FulfillmentEvent;
use parent "WWW::Shopify::Model::Item";

my $fields; sub fields { return $fields; } 
BEGIN { $fields = {
	"id" => new WWW::Shopify::Field::Identifier(),
	"shop_id" => new WWW::Shopify::Field::Identifier(),
	"fulfillment_id" => new WWW::Shopify::Field::Relation::Parent('WWW::Shopify::Model::Order::Fulfillment'),
	"created_at" => new WWW::Shopify::Field::Date(),
	"updated_at" => new WWW::Shopify::Field::Date(),
	"status" => new WWW::Shopify::Field::String::Enum([qw(in_transit confirmed out_for-delivery delivered failure)]),
	"happend_at" => new WWW::Shopify::Field::Timestamp(),
	"message" => new WWW::Shopify::Field::String(),
	"city" => new WWW::Shopify::Field::String::City(),
	"province" => new WWW::Shopify::Field::String::ProvinceCode(),
	"zip" => new WWW::Shopify::Field::String::Zip(),
	"country_code" => new WWW::Shopify::Field::String::CountryCode(),
	"address1" => new WWW::Shopify::Field::String::Address(),
	"latitude" => new WWW::Shopify::Field::Float(-90, 90),
	"longitude" => new WWW::Shopify::Field::Float(-180, 180),
} }

sub url_plural { return 'events'; }
sub read_scope { return "read_fulfillments"; }
sub write_scope { return "write_fulfillments"; }
sub parent { return 'WWW::Shopify::Model::Order::Fulfillment'; }

sub creation_minimal { return qw(status); }

eval(__PACKAGE__->generate_accessors); die $@ if $@;

1;
