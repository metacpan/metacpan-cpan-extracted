#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify;

package WWW::Shopify::Model::Order::Fulfillment::Receipt;
use parent "WWW::Shopify::Model::NestedItem";

my $fields; sub fields { return $fields; } 
BEGIN { $fields = {
	"testcase" => new WWW::Shopify::Field::Boolean(),
	"authorization" => new WWW::Shopify::Field::String("[0-9]{5,10}")};
}
sub creation_minimal { return qw(title); }
sub creation_filled { return qw(id); }

sub identifier { (); }

eval(__PACKAGE__->generate_accessors); die $@ if $@;

1;
