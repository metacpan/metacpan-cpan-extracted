#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify;

package WWW::Shopify::Model::APIPermission;
use parent 'WWW::Shopify::Model::Item';

my $fields; sub fields { return $fields; } 
BEGIN { $fields = {
	"id" => new WWW::Shopify::Field::Identifier(),
	"callback_url" => new WWW::Shopify::Field::String::URL(),
	"preferences_url" => new WWW::Shopify::Field::String::URL(),
	"app_url" => new WWW::Shopify::Field::String::URL(),
	"api_permissions_count" => new WWW::Shopify::Field::Int(),
	"api_client" => new WWW::Shopify::Field::Relation::OwnOne("WWW::Shopify::Model::APIClient"),
	"access_token" => new WWW::Shopify::Field::String::Hash()
}; }

sub singular { return "api_permission"; }
sub needs_login { return 1; }
sub updatable { return undef; }
sub deletable { return undef; }
sub countable { return undef; }

sub creation_filled { return qw(id); }

eval(__PACKAGE__->generate_accessors); die $@ if $@;

1;
