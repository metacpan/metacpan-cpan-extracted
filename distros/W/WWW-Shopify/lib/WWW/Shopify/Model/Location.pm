#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify;

package WWW::Shopify::Model::Location;
use parent 'WWW::Shopify::Model::Item';

my $fields; sub fields { return $fields; } 
BEGIN { $fields = {
	"id" => new WWW::Shopify::Field::Identifier(),
	"name" => new WWW::Shopify::Field::String(),
	"location_type" => new WWW::Shopify::Field::String(),
	"address1" => new WWW::Shopify::Field::String::Address(),
	"address2" => new WWW::Shopify::Field::String::Address(),
	"zip" => new WWW::Shopify::Field::String::Zip(),
	"city" => new WWW::Shopify::Field::String::City(),
	"province" => new WWW::Shopify::Field::String::Province(),
	"country" => new WWW::Shopify::Field::String::Country(),
	"phone" => new WWW::Shopify::Field::String::Phone(),
	"created_at" => new WWW::Shopify::Field::Date(),
	"updated_at" => new WWW::Shopify::Field::Date(),

}; }

sub creatable { return undef; }
sub updatable { return undef; }
sub deletable { return undef; }
sub countable { return undef; }

eval(__PACKAGE__->generate_accessors); die $@ if $@;

1;
