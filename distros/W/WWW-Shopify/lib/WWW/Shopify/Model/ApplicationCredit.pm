#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify;

package WWW::Shopify::Model::ApplicationCredit;
use parent "WWW::Shopify::Model::Item";

my $fields; sub fields { return $fields; } 
BEGIN { $fields = {
	"description" => new WWW::Shopify::Field::String::Words(),
	"id" => new WWW::Shopify::Field::Identifier(),
	"amount" => new WWW::Shopify::Field::Money(),
	"test" => new WWW::Shopify::Field::Boolean()
}; }
sub countable { return undef; }

sub creation_minimal { return qw(amount description); }
sub creation_filled { return qw(id amount description); }

eval(__PACKAGE__->generate_accessors); die $@ if $@;

1;
