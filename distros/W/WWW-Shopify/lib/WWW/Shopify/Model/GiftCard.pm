#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify;

package WWW::Shopify::Model::GiftCard;
use parent "WWW::Shopify::Model::Item";

my $fields; sub fields { return $fields; } 
BEGIN { $fields = {
	"api_client_id" => new WWW::Shopify::Field::String(),
	"balance" => new WWW::Shopify::Field::Money(),
	"created_at" => new WWW::Shopify::Field::Date(),
	"currency" => new WWW::Shopify::Field::Currency(),
	"customer_id" => new WWW::Shopify::Field::Relation::ReferenceOne("WWW::Shopify::Model::Customer"),
	"disabled_at" => new WWW::Shopify::Field::Date(),
	"expires_on" => new WWW::Shopify::Field::Date(),
	"id" => new WWW::Shopify::Field::Identifier(),
	"initial_value" => new WWW::Shopify::Field::Money(),
	"order_id" => new WWW::Shopify::Field::Relation::ReferenceOne("WWW::Shopify::Model::Order"),
	"line_item_id" => new WWW::Shopify::Field::Relation::ReferenceOne("WWW::Shopify::Model::Order::LineItem"),
	"note" => new WWW::Shopify::Field::String(),
	"template_suffix" => new WWW::Shopify::Field::String(),
	"updated_at" => new WWW::Shopify::Field::Date(),
	"user_id" => new WWW::Shopify::Field::Relation::ReferenceOne("WWW::Shopify::Model::User"),
	"code" => new WWW::Shopify::Field::String(),
	"masked_code" => new WWW::Shopify::Field::String::Regex('···· ···· ···· \w{4}'),
	"last_characters" => new WWW::Shopify::Field::String::Regex('\w{4}'),
}; }
sub singular { return 'gift_card'; }
sub creation_minimal { return qw(initial_value code); }
sub creation_filled { return qw(created_at); }
sub update_filled { return qw(updated_at); }
sub get_fields { return grep { $_ ne "code" } keys(%{$_[0]->fields}); }

sub actions { return qw(disable enable); }

sub needs_plus { return 1; }
sub error_codes_if_unavailable { (403, 404) }

sub searchable($) { return 1; }

sub read_scope { return "read_gift_cards"; }
sub write_scope { return "write_gift_cards"; }
sub actually_needs_scope { 0; }

sub update_fields { return qw(expires_on note template_suffix); }

eval(__PACKAGE__->generate_accessors); die $@ if $@;

1;
