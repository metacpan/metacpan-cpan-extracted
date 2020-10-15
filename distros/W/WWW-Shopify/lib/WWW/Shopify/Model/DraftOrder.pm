
#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify;

package WWW::Shopify::Model::DraftOrder;
use parent "WWW::Shopify::Model::Item";

my $fields; sub fields { return $fields; } 
BEGIN { $fields = {
	"id" => new WWW::Shopify::Field::Identifier(),
	"note" => new WWW::Shopify::Field::String::Words(),
	"email" => new WWW::Shopify::Field::String::Email(),
	"taxes_included" => new WWW::Shopify::Field::Boolean(),
	"currency" => new WWW::Shopify::Field::Currency(),
	"subtotal_price" => new WWW::Shopify::Field::Money(),
	"total_tax" => new WWW::Shopify::Field::Money(),
	"total_price" => new WWW::Shopify::Field::Money(),
	"invoice_sent_at" => new WWW::Shopify::Field::Date(),
	"created_at" => new WWW::Shopify::Field::Date(),
	"updated_at" => new WWW::Shopify::Field::Date(),
	"tax_exempt" => new WWW::Shopify::Field::Boolean(),
	"completed_at" => new WWW::Shopify::Field::Date(),
	"name" => new WWW::Shopify::Field::String(),
	"status" => new WWW::Shopify::Field::String::Enum(["open", "invoice_sent", "completed"]),
	"billing_address" => new WWW::Shopify::Field::Relation::OwnOne("WWW::Shopify::Model::DraftOrder::BillingAddress"),
	"shipping_address" => new WWW::Shopify::Field::Relation::OwnOne("WWW::Shopify::Model::DraftOrder::ShippingAddress"),
	"invoice_url" => new WWW::Shopify::Field::String::URL(),
	"applied_discount" => new WWW::Shopify::Field::Money(),
	"order_id" => new WWW::Shopify::Field::Relation::ReferenceOne('WWW::Shopify::Model::Order'),
	"line_items" => new WWW::Shopify::Field::Relation::Many('WWW::Shopify::Model::DraftOrder::LineItem'),
	"shipping_line" => new WWW::Shopify::Field::Relation::OwnOne('WWW::Shopify::Model::DraftOrder::ShippingLine'),
	"tax_lines" => new WWW::Shopify::Field::Relation::Many('WWW::Shopify::Model::DraftOrder::TaxLine'),
	"note_attributes" => new WWW::Shopify::Field::Relation::Many('WWW::Shopify::Model::DraftOrder::NoteAttribute'),
	"tags" => new WWW::Shopify::Field::String(),
	"customer" => new WWW::Shopify::Field::Relation::OwnOne('WWW::Shopify::Model::Customer'),
} }
my $queries; sub queries { return $queries; }
BEGIN { $queries = {
	since_id => new WWW::Shopify::Query::LowerBound('id'),
	status => new WWW::Shopify::Query::Enum('status', ['open', 'invoice_sent', 'completed']),
	ids => new WWW::Shopify::Query::MultiMatch('id')
}; }

sub creation_filled { return qw(invoice_url) }
sub update_fields { return qw(note note_attributes email buyer_accepts_marketing customer tags name shipping_address metafields); };
sub actions { return qw(send_invoice); }


eval(__PACKAGE__->generate_accessors); die $@ if $@;

1
