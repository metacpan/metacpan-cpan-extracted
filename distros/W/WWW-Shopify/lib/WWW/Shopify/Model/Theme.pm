#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify;

package WWW::Shopify::Model::Theme;
use parent 'WWW::Shopify::Model::Item';

my $fields; sub fields { return $fields; } 
BEGIN { $fields = {
	"name" => new WWW::Shopify::Field::String::Words(1),
	"role" => new WWW::Shopify::Field::String::Enum(["main", "mobile", "unpublished"]),
	"id" => new WWW::Shopify::Field::Identifier(),
	"created_at" => new WWW::Shopify::Field::Date(),
	"updated_at" => new WWW::Shopify::Field::Date(),
	"assets" => new WWW::Shopify::Field::Relation::Many('WWW::Shopify::Model::Asset')
}; }

sub countable { return 0; }

sub get_fields { return grep { $_ ne "assets" } keys(%$fields); }
sub creation_minimal { return qw(name role); }
sub creation_filled { return qw(id created_at); }
sub update_filled { return qw(updated_at); }
sub update_fields { return qw(role name); }

sub read_scope { return "read_themes"; }
sub write_scope { return "write_themes"; }

eval(__PACKAGE__->generate_accessors); die $@ if $@;

1
