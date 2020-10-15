#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify;

package WWW::Shopify::Model::CustomerSavedSearch;
use parent "WWW::Shopify::Model::Item";

my $fields; sub fields { return $fields; } 
BEGIN { $fields = {
	"created_at" => new WWW::Shopify::Field::Date(),
	"updated_at" => new WWW::Shopify::Field::Date(),
	"id" => new WWW::Shopify::Field::Identifier(),
	"name" => new WWW::Shopify::Field::String::Words(1, 3),
	"query" => new WWW::Shopify::Field::String::Custom(sub { 
		return 1;
	})
}; }

sub plural { 'customer_saved_searches' }
sub creation_minimal { return qw(name query); }
sub creation_filled { return qw(created_at id); }
sub update_filled { return qw(updated_at); }
sub update_fields { return qw(name query); }
sub throws_webhooks { return 0; }

sub read_scope { return "read_customers"; }
sub write_scope { return "write_customers"; }

eval(__PACKAGE__->generate_accessors); die $@ if $@;

1;
