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
	"country" => new WWW::Shopify::Field::String::CountryCode(),
	"country_name" => new WWW::Shopify::Field::String::Country(),
	"country_code" => new WWW::Shopify::Field::String::CountryCode(),
	"created_at" => new WWW::Shopify::Field::Date(),
	"updated_at" => new WWW::Shopify::Field::Date(),
	"customer_email" => new WWW::Shopify::Field::String::Email(),
	"domain" => new WWW::Shopify::Field::String::Hostname(),
	"email" => new WWW::Shopify::Field::String::Email(),
	"google_apps_domain" => new WWW::Shopify::Field::String::Hostname::Shopify(),
	"google_apps_login_enabled" => new WWW::Shopify::Field::Boolean(),
	"name" => new WWW::Shopify::Field::String::Words(1, 3),
	"phone" => new WWW::Shopify::Field::String::Phone(),
	"province" => new WWW::Shopify::Field::String::Province(),
	"province_code" => new WWW::Shopify::Field::String::ProvinceCode(),
	"public" => new WWW::Shopify::Field::String(),
	"source" => new WWW::Shopify::Field::String(),
	"display_plan_name" => new WWW::Shopify::Field::String::Enum([qw(development affiliate unlimited professional basic shopify_plus custom business dormant comped trial starter staff npo_full singtel_professional nonprofit rogers_basic singtel_starter singtel_basic uafrica_basic npo_lite)]),
	"zip" => new WWW::Shopify::Field::String(),
	"currency" => new WWW::Shopify::Field::Currency(),
	"iana_timezone" => new WWW::Shopify::Field::Timezone::IANA(),
	"timezone" => new WWW::Shopify::Field::Timezone(),
	"latitude" => new WWW::Shopify::Field::Float(),
	"longitude" => new WWW::Shopify::Field::Float(),
	"shop_owner" => new WWW::Shopify::Field::String::Name(),
	"money_format" => new WWW::Shopify::Field::String(),
	"money_with_currency_format" => new WWW::Shopify::Field::String(),
	"money_in_emails_format" => new WWW::Shopify::Field::String(),
	"money_with_currency_in_emails_format" => new WWW::Shopify::Field::String(),
	"taxes_included" => new WWW::Shopify::Field::String(),
	"tax_shipping" => new WWW::Shopify::Field::String(),
	"primary_locale" => new WWW::Shopify::Field::String(),
	"primary_location" => new WWW::Shopify::Field::Relation::ReferenceOne('WWW::Shopify::Model::Location'),
	"plan_name" => new WWW::Shopify::Field::String::Enum([qw(development affiliate unlimited professional basic shopify_plus custom business dormant comped trial starter staff npo_full singtel_professional nonprofit rogers_basic singtel_starter singtel_basic uafrica_basic npo_lite)]),
	"myshopify_domain" => new WWW::Shopify::Field::String::Hostname::Shopify(),
	"metafields" => new WWW::Shopify::Field::Relation::Many("WWW::Shopify::Model::Metafield"),
	"has_giftcards" => new WWW::Shopify::Field::Boolean(),
	"has_discounts" => new WWW::Shopify::Field::Boolean(),
	"password_enabled" => new WWW::Shopify::Field::Boolean(),
	"eligible_for_payments" => new WWW::Shopify::Field::Boolean(),
	"requires_extra_payments_agreement" => new WWW::Shopify::Field::Boolean(),
	"eligible_for_card_reader_giveaway" => new WWW::Shopify::Field::Boolean(),
	"finances" => new WWW::Shopify::Field::Boolean(),
	"cookie_consent_level" => new WWW::Shopify::Field::String(),
	"visitor_tracking_consent_preference" => new WWW::Shopify::Field::String(),
	"force_ssl" => new WWW::Shopify::Field::Boolean(),
	"checkout_api_supported" => new WWW::Shopify::Field::Boolean(),
	"multi_location_enabled" => new WWW::Shopify::Field::Boolean(),
	"setup_required" => new WWW::Shopify::Field::Boolean(),
	"pre_launch_enabled" => new WWW::Shopify::Field::Boolean(),
	"enabled_presentment_currencies" => new WWW::Shopify::Field::Freeform::Array()
}; }

sub creatable($) { return undef; }
sub updatable($) { return undef; }
sub deletable($) { return undef; }
sub countable { return undef; }

sub webhook_topic { return 'shop'; }
sub throws_update_webhooks { 1; }

sub is_shop { return 1; }

eval(__PACKAGE__->generate_accessors); die $@ if $@;

1
