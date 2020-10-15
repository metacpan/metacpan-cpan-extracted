use strict;
use warnings;

use WWW::Shopify;

package WWW::Shopify::Model::Blog;
use parent 'WWW::Shopify::Model::Item';

my $fields; sub fields { return $fields; } 
BEGIN { $fields = {
	"title" => new WWW::Shopify::Field::String::Words(1, 3),
	"handle" => new WWW::Shopify::Field::String::Handle(),
	"commentable" => new WWW::Shopify::Field::String("(no|yes)"),
	"tags" => new WWW::Shopify::Field::String(),
	"metafields" => new WWW::Shopify::Field::Relation::Many("WWW::Shopify::Model::Metafield"),
	"id" => new WWW::Shopify::Field::Identifier(),
	"created_at" => new WWW::Shopify::Field::Date(),
	"updated_at" => new WWW::Shopify::Field::Date(),
	"feedburner" => new WWW::Shopify::Field::String(),
	"feedburner_location" => new WWW::Shopify::Field::String(),
	"template_suffix" => new WWW::Shopify::Field::String(),
	"articles" => new WWW::Shopify::Field::Relation::Many("WWW::Shopify::Model::Article"),
}; }

sub creation_minimal { return qw(title); }
sub creation_filled { return qw(id created_at); }
sub update_filled { return qw(updated_at); }
sub update_fields { return qw(title handle commentable tags metafields feedburner beedburner_location template_suffix); }

sub read_scope { return "read_content"; }
sub write_scope { return "write_content"; }

sub has_metafields { return 1; }

eval(__PACKAGE__->generate_accessors); die $@ if $@;

1
