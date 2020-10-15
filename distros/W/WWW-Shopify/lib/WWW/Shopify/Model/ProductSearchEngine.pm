#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify;

package WWW::Shopify::Model::ProductSearchEngine;
use parent "WWW::Shopify::Model::Item";

my $fields; sub fields { return $fields; } 
BEGIN { $fields = {
	"created_at" => new WWW::Shopify::Field::Date(),
	"name" => new WWW::Shopify::Field::Identifier::String()};
}

sub needs_login { 1; }

sub creatable($) { return undef; }
sub updatable($) { return undef; }
sub deletable($) { return undef; }

eval(__PACKAGE__->generate_accessors); die $@ if $@;

1;
