#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify;

package WWW::Shopify::Model::Customer;
use parent "WWW::Shopify::Model::Item";

my $fields; sub fields { return $fields; } 
BEGIN { $fields = {
	"accepts_marketing" => new WWW::Shopify::Field::Boolean(),
	"created_at" => new WWW::Shopify::Field::Date(),
	"email" => new WWW::Shopify::Field::String::Email(),
	"phone" => new WWW::Shopify::Field::String::Phone(),
	"first_name" => new WWW::Shopify::Field::String::FirstName(),
	"id" => new WWW::Shopify::Field::Identifier(),
	"last_name" => new WWW::Shopify::Field::String::LastName(),
	"last_order_id" => new WWW::Shopify::Field::Relation::ReferenceOne('WWW::Shopify::Model::Order'),
	"note" => new WWW::Shopify::Field::String::Words(0, 6),
	"orders_count" => new WWW::Shopify::Field::Int(0, 1000),
	"state" => new WWW::Shopify::Field::String::Enum([qw(disabled invited enabled declined)]),
	"total_spent" => new WWW::Shopify::Field::Money(),
	"updated_at" => new WWW::Shopify::Field::Date(),
	"tags" => new WWW::Shopify::Field::String::Words(0, 6),
	"last_order_name" => new WWW::Shopify::Field::String(),
	"default_address" => new WWW::Shopify::Field::Relation::OwnOne('WWW::Shopify::Model::Customer::Address'),
	"addresses" => new WWW::Shopify::Field::Relation::Many('WWW::Shopify::Model::Customer::Address'),
	"metafields" => new WWW::Shopify::Field::Relation::Many("WWW::Shopify::Model::Metafield"),
	"image_url" => new WWW::Shopify::Field::String::URL(),
	"send_email_invite" => new WWW::Shopify::Field::Boolean(),
	"send_email_welcome" => new WWW::Shopify::Field::Boolean(),
	"password" => new WWW::Shopify::Field::String::Password(),
	"multipass_identifier" => new WWW::Shopify::Field::String(),
	"password_confirmation" => new WWW::Shopify::Field::String::Password(),
	"verified_email" => new WWW::Shopify::Field::Boolean(),
	"tax_exempt" => new WWW::Shopify::Field::Boolean(),
	"tax_exemptions" => new WWW::Shopify::Field::String(),
	"currency" => new WWW::Shopify::Field::Currency(),
	"marketing_opt_in_level" => new WWW::Shopify::Field::String::Enum([qw(single_opt_in confirmed_opt_in unknown)])
}; }

my $queries; sub queries { return $queries; }
BEGIN { $queries = {
	created_at_min => new WWW::Shopify::Query::LowerBound('created_at'),
	created_at_max => new WWW::Shopify::Query::UpperBound('created_at'),
	updated_at_min => new WWW::Shopify::Query::LowerBound('updated_at'),
	updated_at_max => new WWW::Shopify::Query::UpperBound('updated_at'),
	name => new WWW::Shopify::Query::Match('name'),
	status => new WWW::Shopify::Query::Enum('status', ['open', 'closed', 'cancelled', 'any']),
	financial_status => new WWW::Shopify::Query::Enum('financial_status', ['authorized', 'pending', 'paid', 'partially_paid', 'abandoned', 'refunded', 'voided', 'any']),
	fulfillment_status => new WWW::Shopify::Query::Enum('fulfillment_status', ['shipped', 'partial', 'unshipped', 'any']),
	since_id => new WWW::Shopify::Query::LowerBound('id')
}; }
sub unique_fields { return qw(email); }

sub get_fields { return grep { $_ ne "password" && $_ ne "password_confirmation" && $_ ne "send_email_invite" } keys(%{$_[0]->fields}); }
sub creation_minimal { return qw(email); }
sub creation_filled { return qw(created_at); }
sub update_filled { return qw(updated_at); }
sub update_fields { return qw(email password password_confirmation metafields last_name first_name accepts_marketing tags note state send_email_invite addresses tax_exempt phone); }
sub throws_webhooks { return 1; }

sub searchable($) { return 1; }

sub read_scope { return "read_customers"; }
sub write_scope { return "write_customers"; }

sub actions { return qw(enable disable account_activation_url); }

eval(__PACKAGE__->generate_accessors); die $@ if $@;

1;
