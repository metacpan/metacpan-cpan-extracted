#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify;

package WWW::Shopify::Model::Payout;
use parent "WWW::Shopify::Model::Item";

my $fields; sub fields { return $fields; } 
BEGIN { $fields = {
	"id" => new WWW::Shopify::Field::Identifier(),
	"amount" => new WWW::Shopify::Field::Money(),
	"currency" => new WWW::Shopify::Field::Currency(),
	"status" => new WWW::Shopify::Field::String::Enum([qw(scheduled in_transit paid failed cancelled)]),
	"date" => new WWW::Shopify::Field::Date()
}; }
my $queries; sub queries { return $queries; }
BEGIN { $queries = {
	since_id => new WWW::Shopify::Query::LowerBound('id'),
	date_min => new WWW::Shopify::Query::LowerBound('date'),
	date_max => new WWW::Shopify::Query::UpperBound('date'),
	status => new WWW::Shopify::Query::Enum('status', [qw(scheduled in_transit paid failed cancelled)]),
	date => new WWW::Shopify::Query::Match('date')
}; }

sub updatable { undef };
sub creatable { undef };
sub countable { undef };


sub read_scope { return "read_shopify_payments_payouts"; }

eval(__PACKAGE__->generate_accessors); die $@ if $@;

1;
