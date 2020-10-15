use strict;
use warnings;

use WWW::Shopify;

package WWW::Shopify::Model::MarketingEvent;
use parent 'WWW::Shopify::Model::Item';

my $fields; sub fields { return $fields; } 
BEGIN { $fields = {
	"id" => new WWW::Shopify::Field::Identifier(),
	"remote_id" => new WWW::Shopify::Field::String(),
	"event_type" => new WWW::Shopify::Field::String::Enum([qw(ad post message retargeting transactional affiliate loyalty newsletter abandoned_cart)]),
	"marketing_type" => new WWW::Shopify::Field::String::Enum([qw(social search display email referral)]),
	"paid" => new WWW::Shopify::Field::Boolean(),
	"referring_domain" => new WWW::Shopify::Field::String::URL::Domain(),
	"budget" => new WWW::Shopify::Field::Money(),
	"currency" => new WWW::Shopify::Field::Currency(),
	"budget_type" => new WWW::Shopify::Field::String::Enum([qw(daily lifetime)]),
	"started_at" => new WWW::Shopify::Field::Date(),
	"scheduled_to_end_at" => new WWW::Shopify::Field::Date(),
	"ended_at" => new WWW::Shopify::Field::Date(),
	"utm_campaign" => new WWW::Shopify::Field::String(),
	"utm_source" => new WWW::Shopify::Field::String(),
	"utm_medium" => new WWW::Shopify::Field::String(),
	"utm_term" => new WWW::Shopify::Field::String(),
	"utm_content" => new WWW::Shopify::Field::String(),
	"description" => new WWW::Shopify::Field::Text(),
	"manage_url" => new WWW::Shopify::Field::String::URL(),
	"preview_url" => new WWW::Shopify::Field::String::URL(),
	"marketed_resources" => new WWW::Shopify::Field::Freeform::Hash()
}; }

sub creation_minimal { return qw(title); }
sub creation_filled { return qw(id created_at); }
sub update_filled { return qw(updated_at); }
sub update_fields { return qw(title handle commentable tags metafields feedburner beedburner_location template_suffix); }

sub read_scope { return "read_marketing_events"; }
sub write_scope { return "write_marketing_events"; }

sub has_metafields { return 1; }

eval(__PACKAGE__->generate_accessors); die $@ if $@;

1
