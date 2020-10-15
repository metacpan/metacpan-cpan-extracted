#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify;

package WWW::Shopify::Model::GiftCard::Adjustment;
use parent "WWW::Shopify::Model::Item";

my $fields; sub fields { return $fields; } 
BEGIN { $fields = {
	"api_client_id" => new WWW::Shopify::Field::String(),
	"id" => new WWW::Shopify::Field::Identifier(),
	"number" => new WWW::Shopify::Field::Int(),
	"amount" => new WWW::Shopify::Field::Money(),
	"note" => new WWW::Shopify::Field::String(),
	"remote_transaction_ref" => new WWW::Shopify::Field::String(),
	"remote_transaction_url" => new WWW::Shopify::Field::String(),
	"user_id" => new WWW::Shopify::Field::Int(),
	"order_transaction_id" => new WWW::Shopify::Field::Relation::ReferenceOne("WWW::Shopify::Model::Transaction"),
	"created_at" => new WWW::Shopify::Field::Date(),
	"updated_at" => new WWW::Shopify::Field::Date(),
	"processed_at" => new WWW::Shopify::Field::Date(),
}; }
sub creation_minimal { return qw(amount); }
sub creation_filled { return qw(created_at updated_at processed_at); }

sub needs_plus { return 1; }
sub parent { return 'WWW::Shopify::Model::GiftCard'; }

# For now, Shopify DOES NOT require these scopes.
# sub write_scope { 'write_giftcards' }
# sub read_scope { 'read_giftcards' }

eval(__PACKAGE__->generate_accessors); die $@ if $@;

1;
