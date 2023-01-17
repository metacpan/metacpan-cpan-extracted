#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify;

package WWW::Shopify::Model::Metafield;
use parent "WWW::Shopify::Model::Item";

my $fields; sub fields { return $fields; } 
BEGIN { $fields = {
	"created_at" => new WWW::Shopify::Field::Date(),
	"id" => new WWW::Shopify::Field::Identifier(),
	"owner_id" => new WWW::Shopify::Field::Relation::ReferenceOne('WWW::Shopify::Model::Shop'),
	"updated_at" => new WWW::Shopify::Field::Date(),
	"owner_resource" => new WWW::Shopify::Field::String::Enum(["shop"]),
	"description" => new WWW::Shopify::Field::String(),
	"key" => new WWW::Shopify::Field::String(),
	"namespace" => new WWW::Shopify::Field::String(),
	"value_type" => new WWW::Shopify::Field::String::Enum(["integer", "float", "string"]),
	"type" => new WWW::Shopify::Field::String::Enum([qw(single_line_text_field multi_line_text_field page_reference product_reference variant_reference file_reference number_integer number_decimal date date_time url json boolean color weight volume dimension rating)]),
	"value" => new WWW::Shopify::Field::MediumText()
}; }

sub get_all_through_parent { return 1; }
sub get_through_parent { return 1; }
sub create_through_parent { return 1; }
sub update_through_parent { return 1; } 
sub delete_through_parent { return undef; }
sub included_in_parent { return undef; }

sub creation_minimal { return qw(key namespace value); }
sub creation_filled { return qw(created_at id owner_resource); }
sub update_filled { return qw(updated_at); }
sub update_fields { return qw(description key namespace value_type value); }

eval(__PACKAGE__->generate_accessors); die $@ if $@;

1;
