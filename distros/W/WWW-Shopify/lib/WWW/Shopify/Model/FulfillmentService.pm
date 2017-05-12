#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify;

package WWW::Shopify::Model::FulfillmentService;
use parent "WWW::Shopify::Model::Item";

my $fields; sub fields { return $fields; } 
BEGIN { $fields = {
	"callback_url" => new WWW::Shopify::Field::String::URL(),
	"id" => new WWW::Shopify::Field::Identifier(),
	"email" => new WWW::Shopify::Field::String::Email(),
	"handle" => new WWW::Shopify::Field::String::Handle(),
	"include_pending_stock" => new WWW::Shopify::Field::Boolean(),
	"credential1" => new WWW::Shopify::Field::String::Email(),
	"name" => new WWW::Shopify::Field::String(),
	"service_name" => new WWW::Shopify::Field::String(),
	"inventory_management" => new WWW::Shopify::Field::Boolean(),
	"provider_id" => new WWW::Shopify::Field::String(),
	"credential2_exists" => new WWW::Shopify::Field::Boolean(),
	"format" => new WWW::Shopify::Field::String::Enum(["json", "xml"]),
	"requires_shipping_method" => new WWW::Shopify::Field::Boolean(),
	"tracking_support" => new WWW::Shopify::Field::Boolean()
} }
sub cancellable { return undef; }
sub deletable { return undef; }

sub read_scope { return "read_fulfillments"; }
sub write_scope { return "write_fulfillments"; }

sub get_fields { return grep { $_ ne "tracking_support" && $_ ne "requires_shipping_method" && $_ ne "format" && $_ ne "callback_url" && $_ ne "inventory_management" } keys(%{$_[0]->fields}); }
sub creation_minimal { return qw(name callback_url inventory_management tracking_support requires_shipping_method format); }
sub creation_filled { return qw(id); }

eval(__PACKAGE__->generate_accessors); die $@ if $@;

1;
