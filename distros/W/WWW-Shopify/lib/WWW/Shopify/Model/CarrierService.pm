#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify;

package WWW::Shopify::Model::CarrierService;
use parent 'WWW::Shopify::Model::Item';

my $fields; sub fields { return $fields; } 
BEGIN { $fields = {
	"id" => new WWW::Shopify::Field::Identifier(),
	"name" => new WWW::Shopify::Field::String(),
	"callback_url" => new WWW::Shopify::Field::String::URL(),
	"service_discovery" => new WWW::Shopify::Field::Boolean(),
	"active" => new WWW::Shopify::Field::Boolean(),
	"format" => new WWW::Shopify::Field::String::Enum(["json", "xml"]),
	"carrier_service_type" => new WWW::Shopify::Field::String::Enum(["api"]),
}; }

sub creation_minimal { return qw(name callback_url service_discovery); }
sub creation_filled { return qw(id active carrier_service_type); }

sub read_scope { return "read_shipping"; }
sub write_scope { return "write_shipping"; } 

eval(__PACKAGE__->generate_accessors); die $@ if $@;

1;
