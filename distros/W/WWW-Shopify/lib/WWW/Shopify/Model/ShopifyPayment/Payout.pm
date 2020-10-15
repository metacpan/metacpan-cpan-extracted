use strict;
use warnings;

use WWW::Shopify;

package WWW::Shopify::Model::ShopifyPayment::Payout;
use parent "WWW::Shopify::Model::Item";

my $fields; sub fields { return $fields; } 
BEGIN { $fields = {
	"id" => new WWW::Shopify::Field::Identifier(),
	"status" => new WWW::Shopify::Field::String::Enum([qw(scheduled in_transit paid failed cancelled)]),
	"date" => new WWW::Shopify::Field::Date(),
	"currency" => new WWW::Shopify::Field::Currency(),
	"amount" => new WWW::Shopify::Field::Money(),
	"summary" => new WWW::Shopify::Field::Relation::OwnOne('WWW::Shopify::Model::ShopifyPayment::Payout::Summary')
}; }

sub creatable { undef; }
sub updatable { undef; }
sub read_scope { "read_shopify_payments_payouts"; }
sub write_scope { undef; }


# When getting all, if there are no payments, it actually returns a 404 error, rather than empty array.
# SIGH.
my $queries; sub queries { return $queries; }
BEGIN { $queries = {
	since_id => new WWW::Shopify::Query::LowerBound('id'),
	last_id => new WWW::Shopify::Query::UpperBound('id'),
	date_min => new WWW::Shopify::Query::LowerBound('date'),
	date_max => new WWW::Shopify::Query::UpperBound('date'),
	date => new WWW::Shopify::Query::Match('date'),
	payout_id => new WWW::Shopify::Query::Match('payout_id'),
	payout_status => new WWW::Shopify::Query::Match('payout_status'),
	last_id => new WWW::Shopify::Query::UpperBound('id'),
}; }

eval(__PACKAGE__->generate_accessors); die $@ if $@;

sub prefix { '/shopify_payments/'; }

1
