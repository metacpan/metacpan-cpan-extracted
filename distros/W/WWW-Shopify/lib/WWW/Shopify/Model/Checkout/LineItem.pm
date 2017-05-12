#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify;

package WWW::Shopify::Model::Checkout::LineItem;
use parent 'WWW::Shopify::Model::Order::LineItem';

my $line_item_fields; sub fields { return $line_item_fields; }
BEGIN {
	my %permitted_fields = map { $_ => 1 } qw(compare_at_price fulfillment_service grams id line_price price properties quantity requires_shipping sku taxable title product_id variant_id variant_title vendor);
	my $parent_fields = WWW::Shopify::Model::Order::LineItem->fields;
	$line_item_fields = { map { $_ => $parent_fields->{$_} } grep { exists $permitted_fields{$_} } keys(%$parent_fields) };
}

1;