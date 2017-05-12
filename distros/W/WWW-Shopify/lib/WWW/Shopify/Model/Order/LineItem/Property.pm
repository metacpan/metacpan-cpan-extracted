#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify;

package WWW::Shopify::Model::Order::LineItem::Property;
use parent "WWW::Shopify::Model::NestedItem";

my $fields; sub fields { return $fields; } 
BEGIN { $fields = {
	"name" => new WWW::Shopify::Field::String(),
	"value" => new WWW::Shopify::Field::String()};
}

sub plural() { return 'properties'; }
sub creatable { return undef; }
sub updatable { return undef; }
sub deletable { return undef; }

eval(__PACKAGE__->generate_accessors); die $@ if $@;

1
