#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify;

package WWW::Shopify::Model::Page;
use parent 'WWW::Shopify::Model::Item';

my $fields; sub fields { return $fields; } 
BEGIN { $fields = {
	"author" => new WWW::Shopify::Field::String::Name(),
	"body_html" => new WWW::Shopify::Field::Text::HTML(),
	"summary_html" => new WWW::Shopify::Field::Text::HTML(),
	"template_suffix" => new WWW::Shopify::Field::String(),
	"title" => new WWW::Shopify::Field::String::Words(1, 3),
	"handle" => new WWW::Shopify::Field::String::Handle(),
	"metafields" => new WWW::Shopify::Field::Relation::Many("WWW::Shopify::Model::Metafield"),
	"id" => new WWW::Shopify::Field::Identifier(),
	"shop_id" => new WWW::Shopify::Field::Relation::ReferenceOne("WWW::Shopify::Model::Shop"),
	"created_at" => new WWW::Shopify::Field::Date(),
	"updated_at" => new WWW::Shopify::Field::Date(),
	"published_at" => new WWW::Shopify::Field::Date(),
}; }

sub creation_minimal { return qw(title body_html); }
sub creation_filled { return qw(id created_at published_at); }
sub update_filled { return qw(updated_at); }
sub update_fields { return qw(author body_html summary_html title handle metafields published_at template_suffix); }

sub read_scope { return "read_content"; }
sub write_scope { return "write_content"; }

eval(__PACKAGE__->generate_accessors); die $@ if $@;

1;
