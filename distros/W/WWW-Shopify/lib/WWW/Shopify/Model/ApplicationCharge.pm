#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify;

package WWW::Shopify::Model::ApplicationCharge;
use parent "WWW::Shopify::Model::Item";

my $fields; sub fields { return $fields; } 
BEGIN { $fields = {
	"name" => new WWW::Shopify::Field::String::Words(1,3),
	"price" => new WWW::Shopify::Field::Money(),
	"return_url" => new WWW::Shopify::Field::String::URL(),
	"activated_on" => new WWW::Shopify::Field::String::Words(1, 3),
	"billing_on" => new WWW::Shopify::Field::Date(),
	"cancelled_on" => new WWW::Shopify::Field::Date(),
	"created_at" => new WWW::Shopify::Field::Date(),
	"id" => new WWW::Shopify::Field::Identifier(),
	"status" => new WWW::Shopify::Field::String::Enum(["pending", "accepted", "declined"]),
	"test" => new WWW::Shopify::Field::Boolean(),
	"updated_at" => new WWW::Shopify::Field::Date(),
	"confirmation_url" => new WWW::Shopify::Field::String::URL()
}; }
sub countable { return undef; }
sub actions { return qw(activate); }

sub creation_minimal { return qw(name price return_url); }
sub creation_filled { return qw(id created_at confirmation_url); }
sub update_filled { return qw(updated_at); }

eval(__PACKAGE__->generate_accessors); die $@ if $@;

1;
