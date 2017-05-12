#!/usr/bin/perl

use strict;
use warnings;

package WWW::Shopify::Model::SmartCollection::Image;
use parent 'WWW::Shopify::Model::NestedItem';

my $fields; sub fields { return $fields; } 
BEGIN { $fields = {
	"created_at" =>  new WWW::Shopify::Field::Date(),
	"src" =>  new WWW::Shopify::Field::String::URL::Shopify(),
	"attachment" => new WWW::Shopify::Field::String::Base64()
}; }
sub get_fields { return qw(created_at src); }
sub creation_minimal { return qw(attachment); }
sub creation_filled { return qw(src created_at); }

eval(__PACKAGE__->generate_accessors); die $@ if $@;

1;
