#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify;

package WWW::Shopify::Model::Article::Image;
use parent "WWW::Shopify::Model::NestedItem";

my $fields; sub fields { return $fields; } 
BEGIN { $fields = {
	"src" => new WWW::Shopify::Field::String::URL::Image(),
	"created_at" => new WWW::Shopify::Field::Date()
}; }

sub read_scope { return "read_blogs"; }
sub write_scope { return "write_blogs"; }

eval(__PACKAGE__->generate_accessors); die $@ if $@;

1
