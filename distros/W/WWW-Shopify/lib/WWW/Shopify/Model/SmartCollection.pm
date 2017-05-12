#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify;

use WWW::Shopify::Model::SmartCollection::Rule;
use WWW::Shopify::Model::SmartCollection::Image;

package WWW::Shopify::Model::SmartCollection;
use parent 'WWW::Shopify::Model::Item';

sub singular { return "smart_collection"; }
my $fields; sub fields { return $fields; } 
BEGIN { $fields = {
	"body_html" => new WWW::Shopify::Field::Text::HTML(),
	"handle" => new WWW::Shopify::Field::String::Handle(),
	"disjunctive" => new WWW::Shopify::Field::Boolean(),
	"sort_order" => new WWW::Shopify::Field::String::Enum(["manual", "automatic"]),
	"template_suffix" => new WWW::Shopify::Field::String(),
	"title" => new WWW::Shopify::Field::String::Words(1, 2),
	"rules" => new WWW::Shopify::Field::Relation::Many("WWW::Shopify::Model::SmartCollection::Rule"),
	"image" => new WWW::Shopify::Field::Relation::OwnOne("WWW::Shopify::Model::SmartCollection::Image"),
	"id" => new WWW::Shopify::Field::Identifier(),
	"created_at" => new WWW::Shopify::Field::Date(),
	"metafields" => new WWW::Shopify::Field::Relation::Many("WWW::Shopify::Model::Metafield"),
	"updated_at" => new WWW::Shopify::Field::Date(),
	"published_at" => new WWW::Shopify::Field::Date(),
	"published_scope" => new WWW::Shopify::Field::String()
}; }
my $queries; sub queries { return $queries; }
BEGIN { $queries = {
	created_at_min => new WWW::Shopify::Query::LowerBound('created_at'),
	created_at_max => new WWW::Shopify::Query::UpperBound('created_at'),
	updated_at_min => new WWW::Shopify::Query::LowerBound('updated_at'),
	updated_at_max => new WWW::Shopify::Query::UpperBound('updated_at'),
}; }


sub creation_minimal { return qw(title); }
sub creation_filled { return qw(id created_at); }
sub update_filled { return qw(updated_at); }
sub update_fields { return qw(body_html handle sort_order template_suffix title rules image); }
sub has_metafields { return 1; }
sub throws_webhooks { return 1; }

sub read_scope { return "read_products"; }
sub write_scope { return "write_products"; }

eval(__PACKAGE__->generate_accessors); die $@ if $@;

1
