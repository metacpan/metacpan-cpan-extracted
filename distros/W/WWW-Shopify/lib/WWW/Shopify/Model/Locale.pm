#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify;

package WWW::Shopify::Model::Locale;
use parent "WWW::Shopify::Model::Item";

sub countable { return undef; }
sub creatable { return undef; }
sub updatable { return undef; }
sub deletable { return undef; }

my $fields; sub fields { return $fields; } 
BEGIN { $fields = {
	"id" => new WWW::Shopify::Field::Identifier(),
	"name" => new WWW::Shopify::Field::String(),
	"owner_email" => new WWW::Shopify::Field::String(),
	"owner_id" => new WWW::Shopify::Field::BigInt(),
	"owner_name" => new WWW::Shopify::Field::String(),
	"user_count" => new WWW::Shopify::Field::Int(),
	"shop_count" => new WWW::Shopify::Field::Int(),
	"progress" => new WWW::Shopify::Field::Int(),
	"authorships" => new WWW::Shopify::Field::Relation::Many("WWW::Shopify::Model::Locale::Authorship")
}; }

sub needs_login { return 1; }

eval(__PACKAGE__->generate_accessors); die $@ if $@;

1
