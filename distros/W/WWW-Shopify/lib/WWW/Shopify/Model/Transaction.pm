#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify;

package WWW::Shopify::Model::Transaction;
use parent 'WWW::Shopify::Model::Item';

sub parent { return "WWW::Shopify::Model::Order"; }
my $fields; sub fields { return $fields; } 
BEGIN { $fields = {
	"amount" => new WWW::Shopify::Field::Money(),
	"kind" => new WWW::Shopify::Field::String::Enum(["capture", "authorization", "sale", "void", "refund"]),
	"id" => new WWW::Shopify::Field::Identifier(),
	"status" => new WWW::Shopify::Field::String::Enum(["success", "failure", "error"]),
	"receipt" => new WWW::Shopify::Field::Relation::OwnOne("WWW::Shopify::Model::Transaction::Receipt"),
	"created_at" => new WWW::Shopify::Field::Date(),
	"authorization" => new WWW::Shopify::Field::String(),
	"gateway" => new WWW::Shopify::Field::String::Enum(["bogus", "real"]),
	"order_id" => new WWW::Shopify::Field::Relation::Parent('WWW::Shopify::Model::Order'),
	"parent_id" => new WWW::Shopify::Field::Relation::ReferenceOne('WWW::Shopify::Model::Transaction'),
	"test" => new WWW::Shopify::Field::Boolean(),
	"error_code" => new WWW::Shopify::Field::String(),
	"signature" => new WWW::Shopify::Field::String(),
	"source_name" => new WWW::Shopify::Field::String(),
	"currency" => new WWW::Shopify::Field::String(),
	"message" => new WWW::Shopify::Field::Text(),
	"payment_details" => new WWW::Shopify::Field::Relation::OwnOne("WWW::Shopify::Model::Transaction::PaymentDetails"),
	"user_id" => new WWW::Shopify::Field::Relation::ReferenceOne("WWW::Shopify::Model::User"), 
	"device_id" => new WWW::Shopify::Field::String(),
	"currency_exchange_adjustment" => new WWW::Shopify::Field::Relation::OwnOne("WWW::Shopify::Model::Transaction::CurrencyExchangeAdjustment")
	};
}
sub creation_minimal { return qw(kind); }
sub creation_filled { return qw(id created_at); }
sub update_fields { return qw(amount kind); }

sub read_scope { return "read_orders"; }
sub write_scope { return "write_orders"; }

sub included_in_parent { return 0; }

eval(__PACKAGE__->generate_accessors); die $@ if $@;

1
