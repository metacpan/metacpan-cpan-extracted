#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify;

package WWW::Shopify::Model::Webhook;
use parent "WWW::Shopify::Model::Item";

my $fields; sub fields { return $fields; } 
BEGIN { $fields = {
	"format" => new WWW::Shopify::Field::String("(xml|json)"),
	"address" => new WWW::Shopify::Field::String::URL(),
	"topic" => new WWW::Shopify::Field::String::Enum(
		qw(	
			orders/create orders/delete orders/updated orders/paid orders/cancelled orders/fulfilled orders/partially_fulfilled carts/create
			carts/update checkouts/create checkouts/update checkouts/delete products/create products/update
			products/delete collections/create collections/update collections/delete customer_groups/create
			customer_groups/update customer_groups/delete customers/create customers/enable customers/disable
			customers/update customers/delete fulfillments/create fulfillments/update shop/update app/uninstalled refunds/create
			themes/create themes/delete themes/publish themes/update draft_orders/create draft_orders/delete draft_orders/update
			
		)
	),
	"id" => new WWW::Shopify::Field::Identifier(),
	"created_at" => new WWW::Shopify::Field::Date(),
	"updated_at" => new WWW::Shopify::Field::Date()
}; }

my $queries; sub queries { return $queries; }
BEGIN { $queries = {
	topic => new WWW::Shopify::Query::Match('topic')
}; }


# Looks at the topic to termine which package it's related to.
sub related_packages {
	my ($self) = @_;
	return ('WWW::Shopify::Model::Order') if $self->topic =~ m/^orders/;
	return ('WWW::Shopify::Model::Checkout') if $self->topic =~ m/^checkout/;
	return ('WWW::Shopify::Model::Product') if $self->topic =~ m/^product/;
	return ('WWW::Shopify::Model::CustomerGroup') if $self->topic =~ m/^customer_groups/;
	return ('WWW::Shopify::Model::Customer') if $self->topic =~ m/^customers/;
	return ('WWW::Shopify::Model::Order::Fulfillment') if $self->topic =~ m/^fulfillments/;
	return ('WWW::Shopify::Model::Shop') if $self->topic =~ m/^shop/;
	return ('WWW::Shopify::Model::Refund') if $self->topic =~ m/^refunds/;
	return ('WWW::Shopify::Model::Theme') if $self->topic =~ m/^themes/;
	return ('WWW::Shopify::Model::DraftOrder') if $self->topic =~ m/^draft_orders/;
	return ('WWW::Shopify::Model::SmartCollection', 'WWW::Shopify::Model::CustomCollection') if $self->topic =~ m/^collections/;
	return ();
}

sub creation_minimal { return qw(address topic format); }
sub creation_filled { return qw(created_at); }
sub update_filled { return qw(updated_at); }
sub update_fields { return qw(address topic format); }
sub valid_topics { return @{$_[0]->fields->{topic}->{arguments}}; }

eval(__PACKAGE__->generate_accessors); die $@ if $@;

1
