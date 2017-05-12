#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify;

package WWW::Shopify::Model::User;
use parent 'WWW::Shopify::Model::Item';

my $fields; sub fields { return $fields; } 
BEGIN { $fields = {
	"account_owner" => new WWW::Shopify::Field::Boolean(),
	"bio" => new WWW::Shopify::Field::Text(),
	"email" => new WWW::Shopify::Field::String::Email(),
	"first_name" => new WWW::Shopify::Field::String::FirstName(),
	"last_name" => new WWW::Shopify::Field::String::LastName(),
	"id" => new WWW::Shopify::Field::Identifier(),
	"im" => new WWW::Shopify::Field::String::Email(),
	"permissions" => new WWW::Shopify::Field::Freeform(),
	"phone" => new WWW::Shopify::Field::String::Phone(),
	"receive_announcements" => new WWW::Shopify::Field::Int(),
	"url" => new WWW::Shopify::Field::String::URL(),
	"user_type" => new WWW::Shopify::Field::String::Enum(["regular", "open_id", "restricted"])
}; }

sub needs_plus { return 1; }
sub countable { return undef; }
sub creatable { return undef; }
sub deletable { return undef; }
sub updatable { return undef; }

eval(__PACKAGE__->generate_accessors); die $@ if $@;

1
