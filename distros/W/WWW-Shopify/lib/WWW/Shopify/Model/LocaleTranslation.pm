#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify;

package WWW::Shopify::Model::LocaleTranslation;
use parent "WWW::Shopify::Model::Item";

sub countable { return undef; }
sub parent { return "WWW::Shopify::Model::Locale"; }

my $fields; sub fields { return $fields; } 
BEGIN { $fields = {
	"english" => new WWW::Shopify::Field::String(),
	"id" => new WWW::Shopify::Field::Identifier(),
	"locale_id" => new WWW::Shopify::Field::Relation::Parent("WWW::Shopify::Model::Locale"),
	"text" => new WWW::Shopify::Field::Text()
}; }

sub creation_minimal { return qw(english locale_id text); }
sub update_fields { qw(text) }

sub get_through_parent { return undef; }
sub get_all_through_parent { return undef; }

my $queries; sub queries { return $queries; }
BEGIN { $queries = {
	locale_id => new WWW::Shopify::Query::Match('locale_id'),
}; }

sub needs_login { return 1; }

eval(__PACKAGE__->generate_accessors); die $@ if $@;

1
