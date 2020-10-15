#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify;

package WWW::Shopify::Model::UsageCharge;
use parent 'WWW::Shopify::Model::Item';


my $fields; sub fields { return $fields; } 
BEGIN { $fields = {
	"created_at" => new WWW::Shopify::Field::Date(),
	"updated_at" => new WWW::Shopify::Field::Date(),
	"description" => new WWW::Shopify::Field::String(),
	"id" => new WWW::Shopify::Field::Identifier(),
	"price" => new WWW::Shopify::Field::Money(),
	"recurring_application_charge_id" => new WWW::Shopify::Field::Relation::Parent('WWW::Shopify::Model::RecurringApplicationCharge'),
}; }

sub parent { return 'WWW::Shopify::Model::RecurringApplicationCharge'; }
sub singlable { return 1; }
sub countable { return undef; }
sub updatable { return undef; }
sub deletable { return undef; }
sub creation_minimal { return qw(description price); }

eval(__PACKAGE__->generate_accessors); die $@ if $@;

1;
