#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify;

package WWW::Shopify::Model::Asset;
use parent "WWW::Shopify::Model::Item";

sub parent { return "WWW::Shopify::Model::Theme"; }
sub countable { return undef; }
sub identifier { return qw(key theme_id); }

my $fields; sub fields { return $fields; } 
BEGIN { $fields = {
	"key" => new WWW::Shopify::Field::Identifier::String(),
	"value" => new WWW::Shopify::Field::Text::HTML(),
	"theme_id" => new WWW::Shopify::Field::Relation::Parent("WWW::Shopify::Model::Theme"),
	"attachment" => new WWW::Shopify::Field::Text(),
	"public_url" => new WWW::Shopify::Field::String::URL(),
	"source_key" => new WWW::Shopify::Field::String(),
	"src" => new WWW::Shopify::Field::String::URL(),
	"created_at" => new WWW::Shopify::Field::Date(),
	"updated_at" => new WWW::Shopify::Field::Date(),
	"content_type" => new WWW::Shopify::Field::String("image/(gif|jpg|png)"),
	"size" => new WWW::Shopify::Field::Int(1, 5000)
}; }

# Look into finding some way to validate whether it's value OR attachment.
sub creation_minimal { return qw(key); }
sub creation_filled { return qw(public_url created_at); }
sub update_filled { return qw(updated_at size src content_type); }
sub update_fields { qw(attachment value key) }
sub create_method { return "PUT"; }

sub read_scope { return "read_themes"; }
sub write_scope { return "write_themes"; }

eval(__PACKAGE__->generate_accessors); die $@ if $@;

1
