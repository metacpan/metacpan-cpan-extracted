use strict;
use warnings;

use WWW::Shopify;

package WWW::Shopify::Model::ShopifyPayment::Payout::Summary;
use parent "WWW::Shopify::Model::NestedItem";

my $fields; sub fields { return $fields; } 
BEGIN { $fields = {
	"adjustments_fee_amount" => new WWW::Shopify::Field::Money(),
	"adjustments_gross_amount" => new WWW::Shopify::Field::Money(),
	"charges_fee_amount" => new WWW::Shopify::Field::Money(),
	"charges_gross_amount" => new WWW::Shopify::Field::Money(),
	"refunds_fee_amount" => new WWW::Shopify::Field::Money(),
	"refunds_gross_amount" => new WWW::Shopify::Field::Money(),
	"reserved_funds_fee_amount" => new WWW::Shopify::Field::Money(),
	"reserved_funds_gross_amount" => new WWW::Shopify::Field::Money(),
	"retried_payouts_fee_amount" => new WWW::Shopify::Field::Money(),
	"retried_payouts_gross_amount" => new WWW::Shopify::Field::Money()
}; }

sub plural { return 'summaries'; }
sub creatable { undef; }
sub updatable { undef; }
sub read_scope { "read_shopify_payments_payouts"; }
sub write_scope { undef; }

eval(__PACKAGE__->generate_accessors); die $@ if $@;

1
