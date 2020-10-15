#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify;

package WWW::Shopify::Model::ScriptTag;
use parent "WWW::Shopify::Model::Item";

my $fields; sub fields { return $fields; } 
BEGIN { $fields = {
	"created_at" => new WWW::Shopify::Field::Date(),
	"event" => new WWW::Shopify::Field::String::Enum(["onload"]),
	"id" => new WWW::Shopify::Field::Identifier(),
	"src" => new WWW::Shopify::Field::String::URL(),
	"display_scope" => new WWW::Shopify::Field::String::Enum(["online_store", "order_status", "both"]),
	"updated_at" => new WWW::Shopify::Field::Date()
}; }

sub creation_minimal { return qw(event src); }
sub creation_filled { return qw(id created_at); }
sub update_filled { return qw(updated_at); }

sub read_scope { return "read_script_tags"; }
sub write_scope { return "write_script_tags"; }
sub update_fields { return qw(event src); };

eval(__PACKAGE__->generate_accessors); die $@ if $@;

1;
