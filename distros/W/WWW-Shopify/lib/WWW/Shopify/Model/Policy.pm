#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify;

package WWW::Shopify::Model::Policy;
use parent "WWW::Shopify::Model::Item";

sub countable { return undef; }
sub creatable { return undef; }
sub updatable { return undef; }
sub deletable { return undef; }

my $fields; sub fields { return $fields; } 
BEGIN { $fields = {
	"id" => new WWW::Shopify::Field::Identifier(),
	"title" => new WWW::Shopify::Field::String(),
	"body" => new WWW::Shopify::Field::String(),
	"created_at" => new WWW::Shopify::Field::Date(),
	"updated_at" => new WWW::Shopify::Field::Date(),
	"url" => new WWW::Shopify::Field::Text::HTML()
}; }

eval(__PACKAGE__->generate_accessors); die $@ if $@;

1
