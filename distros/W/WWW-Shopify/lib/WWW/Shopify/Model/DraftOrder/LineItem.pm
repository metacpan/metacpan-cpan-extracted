#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify;

package WWW::Shopify::Model::DraftOrder::LineItem;
use parent "WWW::Shopify::Model::NestedItem";

my $fields; sub fields { return $fields; } 

sub identifier { (); }
BEGIN { $fields = {
	"product_id" => new WWW::Shopify::Field::Relation::ReferenceOne('WWW::Shopify::Model::Product', 1),
	"variant_id" => new WWW::Shopify::Field::Relation::ReferenceOne('WWW::Shopify::Model::Product::Variant', 1),
	"title" => new WWW::Shopify::Field::String::Words(),
	# Depsite being on the documentation, this field does not get passed back. It definitely has one internally, but Shopify does not release it.
	# You can infer it from the admin_graph_ql id.
	# "id" => new WWW::Shopify::Field::Identifier(),
	"name" => new WWW::Shopify::Field::String::Words(),
	"variant_title" => new WWW::Shopify::Field::String::Words(),
	"sku" => new WWW::Shopify::Field::String(),
	"vendor" => new WWW::Shopify::Field::String(),
	"price" => new WWW::Shopify::Field::Money(),
	"grams" => new WWW::Shopify::Field::Int(),
	"quantity" => new WWW::Shopify::Field::Int(),
	"requires_shipping" => new WWW::Shopify::Field::Boolean(),
	"taxable" => new WWW::Shopify::Field::Boolean(),
	"gift_card" => new WWW::Shopify::Field::Boolean(),
	"fulfillment_service" => new WWW::Shopify::Field::String::Enum(["automatic", "manual"]),
	"tax_lines" => new WWW::Shopify::Field::Relation::Many("WWW::Shopify::Model::DraftOrder::LineItem::TaxLine"),
	"applied_discount" => new WWW::Shopify::Field::Relation::OwnOne("WWW::Shopify::Model::DraftOrder::LineItem::AppliedDiscount"),
	"properties" => new WWW::Shopify::Field::Relation::Many("WWW::Shopify::Model::DraftOrder::LineItem::Property"),
	"custom" => new WWW::Shopify::Field::Boolean(),
} }

sub singular { return 'line_item'; }
sub creation_filled { return (); }

eval(__PACKAGE__->generate_accessors); die $@ if $@;

1
