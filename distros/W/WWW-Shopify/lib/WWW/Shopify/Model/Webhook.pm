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
			customers/update customers/delete fulfillments/create fulfillments/update shop/update app/uninstalled
			
		)
	),
	"id" => new WWW::Shopify::Field::Identifier(),
	"created_at" => new WWW::Shopify::Field::Date(min => '2010-01-01 00:00:00', max => 'now'),
	"updated_at" => new WWW::Shopify::Field::Date(min => '2010-01-01 00:00:00', max => 'now')
}; }

my $queries; sub queries { return $queries; }
BEGIN { $queries = {
	topic => new WWW::Shopify::Query::Match('topic')
}; }


sub creation_minimal { return qw(address topic format); }
sub creation_filled { return qw(created_at); }
sub update_filled { return qw(updated_at); }
sub update_fields { return qw(address topic format); }
sub valid_topics { return @{$_[0]->fields->{topic}->{arguments}}; }

eval(__PACKAGE__->generate_accessors); die $@ if $@;

1
