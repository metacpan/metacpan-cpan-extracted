#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify;

package WWW::Shopify::Model::Event;
use parent 'WWW::Shopify::Model::Item';

my $fields; sub fields { return $fields; } 
BEGIN { $fields = {
	"arguments" => new WWW::Shopify::Field::String(),
	"id" => new WWW::Shopify::Field::Identifier(),
	"body" => new WWW::Shopify::Field::String(),
	"created_at" => new WWW::Shopify::Field::Date(min => '2010-01-01 00:00:00', max => 'now'),
	"message" => new WWW::Shopify::Field::String::Words(),
	"author" => new WWW::Shopify::Field::String(),
	"subject_id" => new WWW::Shopify::Field::Identifier(),
	"subject_type" => new WWW::Shopify::Field::String::Enum([qw(Article Blog Collection Comment Order Page Product)]),
	"verb" => new WWW::Shopify::Field::String()
}; }

sub get_all_through_parent { return undef; }
sub get_through_parent { return undef; }
sub creatable { return undef; }
sub updatable { return undef; }
sub deletable { return undef; }

my $queries; sub queries { return $queries; }
BEGIN { $queries = {
	created_at_min => new WWW::Shopify::Query::LowerBound('created_at'),
	created_at_max => new WWW::Shopify::Query::UpperBound('created_at'),
	filter => new WWW::Shopify::Query::Enum('subject_type', $fields->{subject_type}->values),
	verb => new WWW::Shopify::Query::Match('verb'),
	since_id => new WWW::Shopify::Query::LowerBound('id')
}; }


eval(__PACKAGE__->generate_accessors); die $@ if $@;

1;
