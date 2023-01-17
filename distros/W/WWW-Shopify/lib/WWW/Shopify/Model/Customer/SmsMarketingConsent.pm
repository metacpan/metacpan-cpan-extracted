#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify;

package WWW::Shopify::Model::Customer::SmsMarketingConsent;
use parent "WWW::Shopify::Model::NestedItem";

my $fields; sub fields { return $fields; } 
BEGIN { $fields = {
	"state" => new WWW::Shopify::Field::String(),
	"opt_in_level" => new WWW::Shopify::Field::String(),
	"consent_updated_at" => new WWW::Shopify::Field::Date(),
	"consent_collected_from" => new WWW::Shopify::Field::String()
}; }

sub included_in_parent { return 1; }

eval(__PACKAGE__->generate_accessors); die $@ if $@;

1;
