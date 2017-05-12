##!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify;

package WWW::Shopify::Model::Locale::Authorship;
use parent "WWW::Shopify::Model::NestedItem";

my $fields; sub fields { return $fields; } 
BEGIN { $fields = {
	"id" => new WWW::Shopify::Field::Identifier(),
	"accepted" => new WWW::Shopify::Field::Boolean(),
	"locale_id" => new WWW::Shopify::Field::Relation::Parent("WWW::Shopify::Model::Locale"),
	"user_id" => new WWW::Shopify::Field::BigInt()
}; }

eval(__PACKAGE__->generate_accessors); die $@ if $@;

1
