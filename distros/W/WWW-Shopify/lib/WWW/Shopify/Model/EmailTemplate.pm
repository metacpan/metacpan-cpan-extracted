#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify;

package WWW::Shopify::Model::EmailTemplate;
use parent "WWW::Shopify::Model::Item";

my $fields; sub fields { return $fields; } 
BEGIN { $fields = {
	"id" => new WWW::Shopify::Field::Identifier(),
	"body" => new WWW::Shopify::Field::Text(),
	"body_html" => new WWW::Shopify::Field::String::HTML(),
	"include_html" => new WWW::Shopify::Field::Boolean(),
	"name" => new WWW::Shopify::Field::String(),
	"title" => new WWW::Shopify::Field::String(),
}; }

sub update_fields { return qw(body_html body include_html title); }

sub countable { return undef; }
sub creatable { return undef; }
sub deletable { return undef; }

sub needs_login { return 1; }

eval(__PACKAGE__->generate_accessors); die $@ if $@;

1;
