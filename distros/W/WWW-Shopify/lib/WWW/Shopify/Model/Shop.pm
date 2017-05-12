#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify;

package WWW::Shopify::Model::Shop;
use parent 'WWW::Shopify::Model::Item';

my $fields; sub fields { return $fields; } 
BEGIN { $fields = {
	"id" => new WWW::Shopify::Field::Identifier(),
	"address1" => new WWW::Shopify::Field::String::Address(),
	"city" => new WWW::Shopify::Field::String::City(),
	"country" => new WWW::Shopify::Field::String("[A-Z]{3}"),
	"country_name" => new WWW::Shopify::Field::String::Country(),
	"country_code" => new WWW::Shopify::Field::String("[A-Z]{3}"),
	"created_at" => new WWW::Shopify::Field::Date(),
	"customer_email" => new WWW::Shopify::Field::String::Email(),
	"domain" => new WWW::Shopify::Field::String::Hostname(),
	"email" => new WWW::Shopify::Field::String::Email(),
	"google_apps_domain" => new WWW::Shopify::Field::String::Hostname::Shopify(),
	"google_apps_login_enabled" => new WWW::Shopify::Field::Boolean(),
	"name" => new WWW::Shopify::Field::String::Words(1, 3),
	"phone" => new WWW::Shopify::Field::String::Phone(),
	"province" => new WWW::Shopify::Field::String::Words(1),
	"province_code" => new WWW::Shopify::Field::String("[A-Z]{3}"),
	"public" => new WWW::Shopify::Field::String(),
	"source" => new WWW::Shopify::Field::String(),
	"display_plan_name" => new WWW::Shopify::Field::String::Enum([qw(development affiliate unlimited professional basic shopify_plus custom business dormant comped trial starter staff npo_full singtel_professional nonprofit rogers_basic singtel_starter singtel_basic uafrica_basic npo_lite)]),
	"zip" => new WWW::Shopify::Field::String("[A-Z][0-9][A-Z] [0-9][A-Z][0-9]"),
	"currency" => new WWW::Shopify::Field::Currency(),
	"iana_timezone" => new WWW::Shopify::Field::Timezone::IANA(),
	"timezone" => new WWW::Shopify::Field::Timezone(),
	"latitude" => new WWW::Shopify::Field::Float(),
	"longitude" => new WWW::Shopify::Field::Float(),
	"shop_owner" => new WWW::Shopify::Field::String::Name(),
	"money_format" => new WWW::Shopify::Field::String("\$ \{\{amount\}\}"),
	"money_with_currency_format" => new WWW::Shopify::Field::String("\$ \{\{amount\}\} USD"),
	"taxes_included" => new WWW::Shopify::Field::String(),
	"tax_shipping" => new WWW::Shopify::Field::String(),
	"plan_name" => new WWW::Shopify::Field::String::Enum([qw(development affiliate unlimited professional basic shopify_plus custom business dormant comped trial starter staff npo_full singtel_professional nonprofit rogers_basic singtel_starter singtel_basic uafrica_basic npo_lite)]),
	"myshopify_domain" => new WWW::Shopify::Field::String::Hostname::Shopify(),
	"metafields" => new WWW::Shopify::Field::Relation::Many("WWW::Shopify::Model::Metafield")
}; }

sub creatable($) { return undef; }
sub updatable($) { return undef; }
sub deletable($) { return undef; }
sub countable { return undef; }

sub is_shop { return 1; }

eval(__PACKAGE__->generate_accessors); die $@ if $@;

1
