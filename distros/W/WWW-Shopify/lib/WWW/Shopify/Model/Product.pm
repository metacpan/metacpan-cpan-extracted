#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify;
use WWW::Shopify::Model::Product::Image;
use WWW::Shopify::Model::Product::Option;
use WWW::Shopify::Model::Product::Variant;

package WWW::Shopify::Model::Product;
use parent "WWW::Shopify::Model::Item";

my $fields; sub fields { return $fields; } 
BEGIN { $fields = {
	"body_html" => new WWW::Shopify::Field::Text::HTML(),
	"variants" => new WWW::Shopify::Field::Relation::Many("WWW::Shopify::Model::Product::Variant", 1),
	"handle" => new WWW::Shopify::Field::String::Handle(),
	"product_type" => new WWW::Shopify::Field::String(),
	"template_suffix" => new WWW::Shopify::Field::String(),
	"published_scope" => new WWW::Shopify::Field::String(),
	"title" => new WWW::Shopify::Field::String(),
	"vendor" => new WWW::Shopify::Field::String(),
	"tags" => new WWW::Shopify::Field::String::Words(0,'*',', '),
	"images" => new WWW::Shopify::Field::Relation::Many("WWW::Shopify::Model::Product::Image"),
	# Useless alias.
	# "image" => new WWW::Shopify::Field::Relation::OwnOne("WWW::Shopify::Model::Product::Image"),
	"options" => new WWW::Shopify::Field::Relation::Many("WWW::Shopify::Model::Product::Option", 1, 3),
	"metafields" => new WWW::Shopify::Field::Relation::Many("WWW::Shopify::Model::Metafield"),
	"id" => new WWW::Shopify::Field::Identifier(),
	"created_at" => new WWW::Shopify::Field::Date(),
	"published_at" => new WWW::Shopify::Field::Date(),
	"published" => new WWW::Shopify::Field::Boolean(),
	"updated_at" => new WWW::Shopify::Field::Date()};
}
my $queries; sub queries { return $queries; }
BEGIN { $queries = {
	created_at_min => new WWW::Shopify::Query::LowerBound('created_at'),
	created_at_max => new WWW::Shopify::Query::UpperBound('created_at'),
	updated_at_min => new WWW::Shopify::Query::LowerBound('updated_at'),
	updated_at_max => new WWW::Shopify::Query::UpperBound('updated_at'),
	published_at_min => new WWW::Shopify::Query::LowerBound('published_at'),
	published_at_max => new WWW::Shopify::Query::UpperBound('published_at'),
	ids => new WWW::Shopify::Query::MultiMatch('id'),
	published_status => new WWW::Shopify::Query::Enum('published_status', ['unpublished', 'published', 'any']),
	product_type => new WWW::Shopify::Query::Match('product_type'),
	vendor => new WWW::Shopify::Query::Match('vendor'),
	handle => new WWW::Shopify::Query::Match('handle'),
	collection_id => new WWW::Shopify::Query::Custom("collection_id", sub { 
		my ($rs, $value) = @_;
		return $rs->search({ 'collection_id' => $value },
			{ 'join' => 'collects','+select' => ['collects.collection_id'], '+as' => ['collection_id'], }
		);
	}),
	since_id => new WWW::Shopify::Query::LowerBound('id')
}; }


sub get_fields { return grep { $_ ne "collects" && $_ ne "published" } keys(%$fields); }
sub creation_minimal { return qw(title); }
sub creation_filled { return qw(id created_at); }
# Odd, even without an update method, it still has an updated at.
sub update_filled { return qw(updated_at); }
sub update_fields { return qw(metafields handle product_type title template_suffix vendor tags images options body_html variants published_at published); }
sub throws_webhooks { return 1; }
sub get_order { ({'asc' => 'title' }, { 'desc' => 'id' }) }

sub read_scope { return "read_products"; }
sub write_scope { return "write_products"; }

eval(__PACKAGE__->generate_accessors); die $@ if $@;

1
