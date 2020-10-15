use strict;
use warnings;

use WWW::Shopify;

package WWW::Shopify::Model::Currency;
use parent "WWW::Shopify::Model::Item";

my $fields; sub fields { return $fields; } 
BEGIN { $fields = {
	"currency" => new WWW::Shopify::Field::Currency(),
	"rate_updated_at" => new WWW::Shopify::Field::Date(),
	"enabled" => new WWW::Shopify::Field::Boolean()
}; }
sub plural { return "currencies"; }

sub creatable { undef; }
sub singlable { undef; }
sub updatable { undef; }

eval(__PACKAGE__->generate_accessors); die $@ if $@;

1
