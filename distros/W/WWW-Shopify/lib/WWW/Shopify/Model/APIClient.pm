#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify;

package WWW::Shopify::Model::APIClient;
use parent 'WWW::Shopify::Model::Item';

my $fields; sub fields { return $fields; } 
BEGIN { $fields = {
	"api_key" => new WWW::Shopify::Field::String::Hash(),
	"api_permissions_count" => new WWW::Shopify::Field::Int(),
	"api_url" => new WWW::Shopify::Field::String::URL(),
	"created_at" => new WWW::Shopify::Field::Date(),
	"embedded" => new WWW::Shopify::Field::Boolean(),
	"id" => new WWW::Shopify::Field::Identifier(),
	"kind" => new WWW::Shopify::Field::String::Enum(["public", "private"]),
	"number" => new WWW::Shopify::Field::Int(),
	"shared_secret" => new WWW::Shopify::Field::String::Hash(),
	"support_url" => new WWW::Shopify::Field::String::URL(),
	"title" => new WWW::Shopify::Field::String::Words(2),
	"visible" => new WWW::Shopify::Field::Boolean(),
	"application_developer" => new WWW::Shopify::Field::Relation::OwnOne("WWW::Shopify::Model::Shop")
}; }

sub singular { return "api_client"; }
sub needs_login { return 1; }
sub updatable { return undef; }
sub countable { return undef; }


sub creation_filled { return qw(id created_at); }

eval(__PACKAGE__->generate_accessors); die $@ if $@;

1;
