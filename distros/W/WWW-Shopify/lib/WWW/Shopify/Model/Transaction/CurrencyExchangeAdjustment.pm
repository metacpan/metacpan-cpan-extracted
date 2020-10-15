#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify;

package WWW::Shopify::Model::Transaction::CurrencyExchangeAdjustment;
use parent 'WWW::Shopify::Model::NestedItem';

my $fields; sub fields { return $fields; } 
BEGIN { $fields = {
	"id" => new WWW::Shopify::Field::Identifier(),
	"adjustment" => new WWW::Shopify::Field::Money(),
	"original_amount" => new WWW::Shopify::Field::Money(),
	"final_amount" => new WWW::Shopify::Field::Money(),
	"currency" => new WWW::Shopify::Field::String(),
}; }

eval(__PACKAGE__->generate_accessors); die $@ if $@;

sub is_single { 1; }

1;
