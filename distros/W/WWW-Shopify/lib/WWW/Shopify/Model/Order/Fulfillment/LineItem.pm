#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify;

package WWW::Shopify::Model::Order::Fulfillment::LineItem;
use parent 'WWW::Shopify::Model::Order::LineItem';
use Clone qw(clone);
my $fields = undef;
sub fields {
	my $self = shift;
	return $fields if $fields;
	$fields = clone($self->SUPER::fields);
	$fields->{properties} = new WWW::Shopify::Field::Relation::Many("WWW::Shopify::Model::Order::Fulfillment::LineItem::Property");
	$fields->{properties}->name('properties');
	$fields->{discount_allocations} = new WWW::Shopify::Field::Relation::Many("WWW::Shopify::Model::Order::Fulfillment::LineItem::DiscountAllocation");
	$fields->{discount_allocations}->name('discount_allocations');
	$fields->{tax_lines} = new WWW::Shopify::Field::Relation::Many("WWW::Shopify::Model::Order::Fulfillment::LineItem::TaxLine");
	$fields->{tax_lines}->name('tax_lines');
	$fields->{origin_location} = new WWW::Shopify::Field::Relation::OwnOne("WWW::Shopify::Model::Order::Fulfillment::LineItem::Location");
	$fields->{origin_location}->name('origin_location');
	$fields->{destination_location} = new WWW::Shopify::Field::Relation::OwnOne("WWW::Shopify::Model::Order::Fulfillment::LineItem::Location");
	$fields->{destination_location}->name('destination_location');
	$fields->{shipment_status} = WWW::Shopify::Field::String::Enum->new([qw(confirmed in_transit out_for_delivery delivered failure)]);
	$fields->{shipment_status}->name('shipment_status');
	return $fields;
}

sub shipment_status { $_[0]->{shipment_status} = $_[1] if int(@_) > 1; return $_[0]->{shipment_status}; }

1;
