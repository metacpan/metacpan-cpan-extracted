#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify;

package WWW::Shopify::Model::Checkout::LineItem;
use parent 'WWW::Shopify::Model::Order::LineItem';

sub identifier { qw() }

my $line_item_fields; sub fields { return $line_item_fields; }
BEGIN {
	my %permitted_fields = map { $_ => 1 } qw(compare_at_price fulfillment_service grams id line_price price properties quantity requires_shipping sku taxable title product_id variant_id variant_title name vendor);
	my $parent_fields = WWW::Shopify::Model::Order::LineItem->fields;
	
	$line_item_fields = { map { $_ => $parent_fields->{$_} } grep { exists $permitted_fields{$_} } keys(%$parent_fields) };
	$line_item_fields->{id} = new WWW::Shopify::Field::Identifier::String();
	$line_item_fields->{id}->name('id');
	
	$line_item_fields->{properties} = new WWW::Shopify::Field::Freeform("WWW::Shopify::Model::Checkout::LineItem::Property");
	$line_item_fields->{properties}->name('properties');
}

1;